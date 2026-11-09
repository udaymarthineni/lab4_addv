module fifomem #(parameter DATASIZE = 8,
 parameter ADDRSIZE = 4) 
 (output [DATASIZE-1:0] rdata,
 input [DATASIZE-1:0] wdata,
 input [ADDRSIZE-1:0] waddr, raddr,
 input wclken, wfull, wclk);
 
 `ifdef VENDORRAM
 
 vendor_ram mem (.dout(rdata), .din(wdata),
 .waddr(waddr), .raddr(raddr),
 .wclken(wclken),
 .wclken_n(wfull), .clk(wclk));
 `else
 // RTL Verilog memory model
 localparam DEPTH = 1<<ADDRSIZE;
 logic [DATASIZE-1:0] mem [0:DEPTH-1];
 assign rdata = mem[raddr];
 // Simulation-only fault: +DROP_N=4 skips every fourth accepted write.
 int drop_n = 0;
 bit [31:0] write_number;
 initial begin
     if ($value$plusargs("DROP_N=%d", drop_n))
         $display("Fault injection: drop every %0d writes", drop_n);
 end

 always_ff @(posedge wclk) begin
     if (wclken && !wfull) begin
         write_number <= write_number + 1;
         if (drop_n > 0 && (write_number + 1) % drop_n == 0)
             $display("DROPPED WRITE #%0d: data=%0h time=%0t",
                      write_number + 1, wdata, $time);
         else
             mem[waddr] <= wdata;
     end
 end
 `endif
endmodule
