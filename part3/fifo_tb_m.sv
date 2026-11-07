//////////////////////////////////////


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Async FIFO - Part 3: SV class-based, scoreboard-based testbench
//
// Interfaces : fifo_wr_bus / fifo_rd_bus (defined in fifo1.sv, one per clock domain)
// Classes    : fifo_txn, fifo_monitor, fifo_scoreboard, fifo_env
// Stimulus   : same directed sequence as Lab 1 (macros below)
//
// Plusarg    : +LOG_LEVEL=0|1|2   (0 = off (default), 1 = brief, 2 = detailed)
// Compile order: fifo1.sv, fifomem.sv, rptr_empty.sv, wptr_full.sv,
//                sync_r2w.sv, sync_w2r.sv, fifo_tb.sv
//////////////////////////////////////////////////////////////////////////////////

typedef enum bit {FIFO_WRITE = 1'b0, FIFO_READ = 1'b1} fifo_op_e;

//------------------------------------------------------------------------------
// Transaction: one write-port or read-port access (a cycle where winc/rinc = 1)
//------------------------------------------------------------------------------
class fifo_txn;
  static int unsigned count = 0;

  int unsigned     id;
  fifo_op_e        op;
  logic [7:0]      data;       // wdata (write) or rdata (read), sampled before the clock edge
  bit              full_empty; // wfull (write) or rempty (read), sampled before the clock edge
  bit              almost;     // almost_wfull (write) or almost_rempty (read)
  bit              accepted;   // inc && !full/empty -> the DUT really performed the access
  realtime         timestamp;  // simulation time (ns) of the sampling clock edge

  function new();
    id = count++;
  endfunction

  function string brief();
    return $sformatf("[%0t] txn #%0d (%s) generated",
                     $time, id, (op == FIFO_WRITE) ? "WRITE" : "READ");
  endfunction

  function string detail();
    string fe, al;
    fe = (op == FIFO_WRITE) ? "wfull"        : "rempty";
    al = (op == FIFO_WRITE) ? "almost_wfull" : "almost_rempty";
    return $sformatf("[%0t] txn #%0d op=%s data=0x%02h %s=%0b %s=%0b accepted=%0b ts=%0.3f ns",
                     $time, id, (op == FIFO_WRITE) ? "WRITE" : "READ", data,
                     fe, full_empty, al, almost, accepted, timestamp);
  endfunction
endclass

//------------------------------------------------------------------------------
// Monitor: watches the pins of both interfaces, builds transactions, posts them
// to ONE mailbox so the scoreboard sees them in simulation-time order.
// Signals are sampled in the active region of the clock edge, i.e. before the
// DUT flops update (NBA region) -> we see exactly what the DUT sees.
//------------------------------------------------------------------------------
class fifo_monitor;
  virtual fifo_wr_bus wvif;
  virtual fifo_rd_bus rvif;
  mailbox #(fifo_txn) mbx;
  int log_level;

  function new(virtual fifo_wr_bus wvif, virtual fifo_rd_bus rvif,
               mailbox #(fifo_txn) mbx);
    this.wvif = wvif;
    this.rvif = rvif;
    this.mbx  = mbx;
    if (!$value$plusargs("LOG_LEVEL=%d", log_level)) log_level = 0;
  endfunction

  task run();
    fork
      mon_write();
      mon_read();
    join_none
  endtask

  task mon_write();
    fifo_txn t;
    forever begin
      @(posedge wvif.wclk);
      if (wvif.wrst_n === 1'b1 && wvif.winc === 1'b1) begin
        t            = new();
        t.op         = FIFO_WRITE;
        t.data       = wvif.wdata;
        t.full_empty = wvif.wfull;
        t.almost     = wvif.almost_wfull;
        t.accepted   = !wvif.wfull;
        t.timestamp  = $realtime;
        mbx.put(t);
        log(t);
      end
    end
  endtask

  task mon_read();
    fifo_txn t;
    forever begin
      @(posedge rvif.rclk);
      if (rvif.rrst_n === 1'b1 && rvif.rinc === 1'b1) begin
        t            = new();
        t.op         = FIFO_READ;
        t.data       = rvif.rdata;
        t.full_empty = rvif.rempty;
        t.almost     = rvif.almost_rempty;
        t.accepted   = !rvif.rempty;
        t.timestamp  = $realtime;
        mbx.put(t);
        log(t);
      end
    end
  endtask

  function void log(fifo_txn t);
    case (log_level)
      0:       ;                                   // logger disabled
      1:       $display("MON: %s", t.brief());
      default: $display("MON: %s", t.detail());
    endcase
  endfunction
endclass

//------------------------------------------------------------------------------
// Scoreboard: queue-based reference model + checks
//------------------------------------------------------------------------------
class fifo_scoreboard;
  localparam int DEPTH            = 16;
  localparam int ALMOST_FULL_LVL  = (DEPTH * 3) / 4;  // 12
  localparam int ALMOST_EMPTY_LVL = DEPTH / 4;        // 4

  mailbox #(fifo_txn) mbx;
  logic [7:0] q[$];               // reference model of the FIFO contents

  int n_wr_ok, n_wr_blocked, n_rd_ok, n_rd_blocked;
  int n_checks, n_errors;

  function new(mailbox #(fifo_txn) mbx);
    this.mbx = mbx;
  endfunction

  task run();
    fifo_txn t;
    forever begin
      mbx.get(t);
      if (t.op == FIFO_WRITE) check_write(t);
      else                    check_read(t);
    end
  endtask

  function void err(fifo_txn t, string msg);
    n_errors++;
    $error("SCB: %s | model_size=%0d | %s", msg, q.size(), t.detail());
  endfunction

  function void check_write(fifo_txn t);
    // C1: wfull must be asserted whenever the reference FIFO is full
    n_checks++;
    if (q.size() == DEPTH && !t.full_empty) err(t, "wfull NOT asserted although FIFO is full");

    // C2: almost_wfull is only possible when the real occupancy is <= 12
    //     (the DUT sees a stale, pessimistic read pointer, never an optimistic one)
    n_checks++;
    if (t.almost && q.size() > ALMOST_FULL_LVL) err(t, "almost_wfull asserted with occupancy above threshold");

    if (t.accepted) begin
      n_checks++;
      if (q.size() >= DEPTH) err(t, "OVERFLOW: DUT accepted a write while model is full");
      else begin
        q.push_back(t.data);
        n_wr_ok++;
      end
    end
    else n_wr_blocked++;   // write dropped because wfull=1 -> model unchanged
  endfunction

  function void check_read(fifo_txn t);
    logic [7:0] exp;

    // C3: rempty must be asserted whenever the reference FIFO is empty
    n_checks++;
    if (q.size() == 0 && !t.full_empty) err(t, "rempty NOT asserted although FIFO is empty");

    // C4: almost_rempty is only possible when real occupancy is >= 4
    n_checks++;
    if (t.almost && q.size() < ALMOST_EMPTY_LVL) err(t, "almost_rempty asserted with occupancy below threshold");

    if (t.accepted) begin
      n_checks++;
      if (q.size() == 0) err(t, "UNDERFLOW: DUT accepted a read while model is empty");
      else begin
        exp = q.pop_front();
        n_rd_ok++;
        // C5: data integrity + ordering
        if (t.data !== exp)
          err(t, $sformatf("DATA MISMATCH: expected 0x%02h, got 0x%02h", exp, t.data));
      end
    end
    else n_rd_blocked++;   // read ignored because rempty=1 -> model unchanged
  endfunction

  function void report();
    $display("--------------------------------------------------------------");
    $display("SCB SUMMARY: writes accepted=%0d blocked(full)=%0d | reads accepted=%0d blocked(empty)=%0d",
             n_wr_ok, n_wr_blocked, n_rd_ok, n_rd_blocked);
    $display("SCB SUMMARY: checks=%0d errors=%0d entries left in model=%0d",
             n_checks, n_errors, q.size());
    if (n_errors == 0) $display("SCB RESULT: PASS");
    else               $display("SCB RESULT: FAIL");
    $display("--------------------------------------------------------------");
  endfunction
endclass

//------------------------------------------------------------------------------
// Environment
//------------------------------------------------------------------------------
class fifo_env;
  mailbox #(fifo_txn) mbx;
  fifo_monitor        mon;
  fifo_scoreboard     scb;

  function new(virtual fifo_wr_bus wvif, virtual fifo_rd_bus rvif);
    mbx = new();                 // unbounded
    mon = new(wvif, rvif, mbx);
    scb = new(mbx);
  endfunction

  task start();
    fork
      mon.run();
      scb.run();
    join_none
  endtask

  task finish();
    wait (mbx.num() == 0);       // scoreboard has consumed everything
    #1;
    scb.report();
  endtask
endclass

//------------------------------------------------------------------------------
// Lab 1 stimulus macros (ported to the two interfaces)
//------------------------------------------------------------------------------
`define W2FIFO(w_data)          \
    begin                       \
    wr_bus.winc  = 1'b1;        \
    wr_bus.wdata = w_data;      \
    wait(wr_bus.wclk == 1'b1);  \
    wait(wr_bus.wclk == 1'b0);  \
    wr_bus.winc  = 1'b0;        \
    end

`define R2FIFO                  \
    begin                       \
    rd_bus.rinc = 1'b1;         \
    wait(rd_bus.rclk == 1'b1);  \
    wait(rd_bus.rclk == 1'b0);  \
    rd_bus.rinc = 1'b0;         \
    end

`define CHECK_FULL                                  \
    begin                                           \
    if (wr_bus.wfull == 1'b1) $display("the fifo is full");     \
    else                      $display("the fifo is not full"); \
    end

`define CHECK_ALMOST_FULL                                       \
    begin                                                       \
    if (wr_bus.almost_wfull == 1'b1) $display("the fifo is almost full");     \
    else                             $display("the fifo is not almost full"); \
    end

`define CHECK_EMPTY                                 \
    begin                                           \
    if (rd_bus.rempty == 1'b1) $display("the fifo is empty");     \
    else                       $display("the fifo is not empty"); \
    end

`define SIMULT_RD_WR(data)      \
    begin                       \
    wr_bus.winc  = 1'b1;        \
    rd_bus.rinc  = 1'b1;        \
    wr_bus.wdata = data;        \
    wait(rd_bus.rclk == 1'b1);  \
    wait(rd_bus.rclk == 1'b0);  \
    wait(wr_bus.wclk == 1'b1);  \
    wait(wr_bus.wclk == 1'b0);  \
    wr_bus.winc = 1'b0;         \
    rd_bus.rinc = 1'b0;         \
    end

`define WAIT_WCLK   begin wait(wr_bus.wclk == 1'b1); wait(wr_bus.wclk == 1'b0); end
`define WAIT_RCLK   begin wait(rd_bus.rclk == 1'b1); wait(rd_bus.rclk == 1'b0); end

//------------------------------------------------------------------------------
// Top
//------------------------------------------------------------------------------
module fifo_tb();

  parameter DSIZE = 8;
  parameter ASIZE = 4;

  fifo_wr_bus wr_bus();
  fifo_rd_bus rd_bus();

  fifo1 dut (.wr_bus(wr_bus), .rd_bus(rd_bus));

  fifo_env env;

`ifdef FSDB
  initial begin
    $fsdbDumpfile("novas.fsdb");
    $fsdbDumpvars(0, fifo_tb);
  end
`endif

  // convenience probes for the waveform viewer
  wire [ASIZE:0] rptr = dut.rptr_empty.rptr;
  wire [ASIZE:0] wptr = dut.wptr_full.wptr;

  // clocks: wclk = 100 MHz, rclk = 50 MHz (same as Lab 1)
  always begin wr_bus.wclk = 1'b0; #5;  wr_bus.wclk = 1'b1; #5;  end
  always begin rd_bus.rclk = 1'b0; #10; rd_bus.rclk = 1'b1; #10; end

  initial begin
    $timeformat(-9, 0, " ns", 0);   // %0t prints in ns
    env = new(wr_bus, rd_bus);
    env.start();

    wr_bus.winc = 1'b0;  rd_bus.rinc = 1'b0;
    wr_bus.wrst_n = 1'b0; rd_bus.rrst_n = 1'b0;

    `WAIT_RCLK `WAIT_RCLK
    rd_bus.rrst_n = 1'b1;
    `WAIT_WCLK `WAIT_WCLK
    wr_bus.wrst_n = 1'b1;

    // -------- Lab 1 stimulus --------
    // ALMOST FULL CHECK CONDITION
    `W2FIFO (8'h00)
    `W2FIFO (8'h01)
    `W2FIFO (8'h02)
    `W2FIFO (8'h03)
    `WAIT_WCLK
    `W2FIFO (8'h04)
    `WAIT_WCLK
    `W2FIFO (8'h05)
    `W2FIFO (8'h06)
    `W2FIFO (8'h07)
    `W2FIFO (8'h08)
    `W2FIFO (8'h09)
    `W2FIFO (8'h0a)
    `CHECK_ALMOST_FULL
    `W2FIFO (8'h0b)
    `CHECK_ALMOST_FULL
    `W2FIFO (8'h0c)
    `W2FIFO (8'h0d)
    `W2FIFO (8'h0e)
    `W2FIFO (8'h0f)
    `W2FIFO (8'h07)           // write attempt while full -> must be dropped

    `WAIT_WCLK `WAIT_WCLK `WAIT_WCLK
    `CHECK_FULL               // fifo full should be checked

    `WAIT_RCLK `WAIT_RCLK

    repeat (16) `R2FIFO       // drain

    `CHECK_EMPTY
    `WAIT_WCLK `WAIT_WCLK
    `WAIT_RCLK
    `CHECK_EMPTY

    `W2FIFO (8'h0d)
    `W2FIFO (8'h0e)
    `W2FIFO (8'h0f)
    `W2FIFO (8'h07)

    `SIMULT_RD_WR(8'h04)
    `SIMULT_RD_WR(8'h05)
    `SIMULT_RD_WR(8'h06)
    `SIMULT_RD_WR(8'h07)

    rd_bus.rinc = 1'b1;       // keep reading until the FIFO runs dry
    repeat (8) `WAIT_RCLK
    rd_bus.rinc = 1'b0;

    #20;
    env.finish();
    $display("FIFO TEST COMPLETED");
    $finish;
  end

endmodule






