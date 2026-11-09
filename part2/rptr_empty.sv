module rptr_empty #(parameter ADDRSIZE = 4)
 (output logic rempty,
 output logic almost_rempty,
 output [ADDRSIZE-1:0] raddr,
 output logic [ADDRSIZE :0] rptr,
 input [ADDRSIZE :0] rq2_wptr,
 input rinc, rclk, rrst_n);
 logic [ADDRSIZE:0] rbin;
 logic [ADDRSIZE:0] rgraynext, rbinnext,wbinnext;
 logic almost_rempty_val;
 integer i;
 
 localparam one_four_depth_fifo = ((1 << ADDRSIZE)/4);
 
 
 //-------------------
 // GRAYSTYLE2 pointer
 //-------------------
 always_ff @(posedge rclk or negedge rrst_n)
 if (!rrst_n) {rbin, rptr} <= 0;
 else {rbin, rptr} <= {rbinnext, rgraynext};
 // Memory read-address pointer (okay to use binary to address memory)
 assign raddr = rbin[ADDRSIZE-1:0];
 assign rbinnext = rbin + (rinc & ~rempty);
 assign rgraynext = (rbinnext>>1) ^ rbinnext;
 //---------------------------------------------------------------
 // FIFO empty when the next rptr == synchronized wptr or on reset
 //---------------------------------------------------------------
 assign rempty_val = (rgraynext == rq2_wptr);
 always_ff @(posedge rclk or negedge rrst_n)
 if (!rrst_n) rempty <= 1'b1;
 else rempty <= rempty_val;
 
 always_comb
 begin
 wbinnext[ADDRSIZE] = rq2_wptr[ADDRSIZE];
 for(i=ADDRSIZE-1;i>=0;i--)
 wbinnext[i] = (wbinnext[i+1] ^rq2_wptr[i]);
 end
 
assign almost_rempty_val = ((wbinnext - rbinnext) == one_four_depth_fifo);


always_ff @(posedge rclk or negedge rrst_n)
  if (!rrst_n) almost_rempty <= 1'b0;
 else almost_rempty <= almost_rempty_val;


endmodule
