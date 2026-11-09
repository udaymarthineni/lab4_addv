`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.09.2026 14:50:51
// Design Name: 
// Module Name: fifo1
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

interface fifo1_bus();
 
 parameter DSIZE = 8;
 parameter ASIZE = 4;
 logic [DSIZE-1:0] rdata;
 logic wfull;
 logic almost_wfull;
 logic rempty;
 logic almost_rempty;
 logic  [DSIZE-1:0] wdata;
 logic winc, wclk, wrst_n;
 logic rinc, rclk, rrst_n;
 
 modport dut
 (
 output  rdata,
 output wfull,
 output almost_wfull,
 output rempty, almost_rempty,
 input  wdata,winc, wclk, wrst_n,rinc, rclk, rrst_n 
 );
 
endinterface



module fifo1 (fifo1_bus.dut bus);
 parameter DSIZE = 8;
 parameter ASIZE = 4;
 
 logic [ASIZE-1:0] waddr, raddr;
 logic [ASIZE:0] wptr, rptr, wq2_rptr, rq2_wptr;
 
 sync_r2w sync_r2w (
  .wq2_rptr (wq2_rptr),
  .rptr     (rptr),
  .wclk     (bus.wclk),
  .wrst_n   (bus.wrst_n)
);

sync_w2r sync_w2r (
  .rq2_wptr (rq2_wptr),
  .wptr     (wptr),
  .rclk     (bus.rclk),
  .rrst_n   (bus.rrst_n)
);

fifomem #(DSIZE, ASIZE) fifomem (
  .rdata  (bus.rdata),
  .wdata  (bus.wdata),
  .waddr  (waddr),
  .raddr  (raddr),
  .wclken (bus.winc),
  .wfull  (bus.wfull),
  .wclk   (bus.wclk)
);

rptr_empty #(ASIZE) rptr_empty (
  .rempty        (bus.rempty),
  .almost_rempty (bus.almost_rempty),
  .raddr         (raddr),
  .rptr          (rptr),
  .rq2_wptr      (rq2_wptr),
  .rinc          (bus.rinc),
  .rclk          (bus.rclk),
  .rrst_n        (bus.rrst_n)
);

wptr_full #(ASIZE) wptr_full (
  .wfull        (bus.wfull),
  .almost_wfull (bus.almost_wfull),
  .waddr        (waddr),
  .wptr         (wptr),
  .wq2_rptr     (wq2_rptr),
  .winc         (bus.winc),
  .wclk         (bus.wclk),
  .wrst_n       (bus.wrst_n)
);
endmodule