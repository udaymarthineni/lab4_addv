module wptr_full #(parameter ADDRSIZE = 4)
 (output logic wfull,
 output logic almost_wfull,
 output [ADDRSIZE-1:0] waddr,
 output logic [ADDRSIZE :0] wptr,
 input [ADDRSIZE :0] wq2_rptr,
 input winc, wclk, wrst_n);
 logic [ADDRSIZE:0] wbin;
 logic [ADDRSIZE:0] wgraynext, wbinnext, rbinnext;
 logic almost_wfull_val ;
 localparam three_four_depth_fifo = ((1 << ADDRSIZE) * 3)/4;
 integer i;
 
 // GRAYSTYLE2 pointer   
 always_ff @(posedge wclk or negedge wrst_n)
 if (!wrst_n) {wbin, wptr} <= 0;
 else {wbin, wptr} <= {wbinnext, wgraynext};     
 // Memory write-address pointer (okay to use binary to address memory)   
 assign waddr = wbin[ADDRSIZE-1:0];
 assign wbinnext = wbin + (winc & ~wfull);
 assign wgraynext = (wbinnext>>1) ^ wbinnext;
 //------------------------------------------------------------------
 // Simplified version of the three necessary full-tests:
 // assign wfull_val=((wgnext[ADDRSIZE] !=wq2_rptr[ADDRSIZE] ) &&
 // (wgnext[ADDRSIZE-1] !=wq2_rptr[ADDRSIZE-1]) &&
 // (wgnext[ADDRSIZE-2:0]==wq2_rptr[ADDRSIZE-2:0]));
 //------------------------------------------------------------------
 assign wfull_val = (wgraynext=={~wq2_rptr[ADDRSIZE:ADDRSIZE-1],
 wq2_rptr[ADDRSIZE-2:0]});
 always_ff @(posedge wclk or negedge wrst_n)
 if (!wrst_n) wfull <= 1'b0;
 else wfull <= wfull_val;
 
 always_comb
 begin
 rbinnext[ADDRSIZE] = wq2_rptr[ADDRSIZE];
 for(i=ADDRSIZE-1;i>=0;i--)
 rbinnext[i] = (rbinnext[i+1] ^wq2_rptr[i]);
 end


 assign almost_wfull_val = ((wbinnext - rbinnext ) == three_four_depth_fifo);
  always_ff @(posedge wclk or negedge wrst_n)
 if (!wrst_n) almost_wfull <= 1'b0;
 else almost_wfull <= almost_wfull_val;

endmodule
