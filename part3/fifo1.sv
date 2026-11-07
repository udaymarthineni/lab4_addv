`timescale 1ns / 1ps

 interface fifo_wr_bus();
  parameter DSIZE = 8;
 
  logic wfull;
  logic almost_wfull;
  logic [DSIZE-1:0] wdata;
  logic winc, wclk, wrst_n;

  modport wr_dut(
    output wfull,
    output almost_wfull,
    input  wdata, winc, wclk, wrst_n
  );
endinterface


 interface fifo_rd_bus();
  parameter DSIZE = 8;
 
  logic [DSIZE-1:0] rdata;
  logic rempty;
  logic almost_rempty;
  logic rinc, rclk, rrst_n;

  modport rd_dut (
    output rdata,
    output rempty, almost_rempty,
    input  rinc, rclk, rrst_n
  );
endinterface


module fifo1 (
  fifo_wr_bus.wr_dut wr_bus,   // write-domain interface (wclk)
  fifo_rd_bus.rd_dut rd_bus    // read-domain interface  (rclk)
);
  parameter DSIZE = 8;
  parameter ASIZE = 4;

  logic [ASIZE-1:0] waddr, raddr;
  logic [ASIZE:0]   wptr, rptr, wq2_rptr, rq2_wptr;

  // read pointer -> write domain
  sync_r2w sync_r2w (
    .wq2_rptr (wq2_rptr),
    .rptr     (rptr),
    .wclk     (wr_bus.wclk),
    .wrst_n   (wr_bus.wrst_n)
  );

  // write pointer -> read domain
  sync_w2r sync_w2r (
    .rq2_wptr (rq2_wptr),
    .wptr     (wptr),
    .rclk     (rd_bus.rclk),
    .rrst_n   (rd_bus.rrst_n)
  );

  fifomem #(DSIZE, ASIZE) fifomem (
    .rdata  (rd_bus.rdata),
    .wdata  (wr_bus.wdata),
    .waddr  (waddr),
    .raddr  (raddr),
    .wclken (wr_bus.winc),
    .wfull  (wr_bus.wfull),
    .wclk   (wr_bus.wclk)
  );

  rptr_empty #(ASIZE) rptr_empty (
    .rempty        (rd_bus.rempty),
    .almost_rempty (rd_bus.almost_rempty),
    .raddr         (raddr),
    .rptr          (rptr),
    .rq2_wptr      (rq2_wptr),
    .rinc          (rd_bus.rinc),
    .rclk          (rd_bus.rclk),
    .rrst_n        (rd_bus.rrst_n)
  );

  wptr_full #(ASIZE) wptr_full (
    .wfull        (wr_bus.wfull),
    .almost_wfull (wr_bus.almost_wfull),
    .waddr        (waddr),
    .wptr         (wptr),
    .wq2_rptr     (wq2_rptr),
    .winc         (wr_bus.winc),
    .wclk         (wr_bus.wclk),
    .wrst_n       (wr_bus.wrst_n)
  );
endmodule