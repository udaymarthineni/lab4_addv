`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.09.2026 16:44:56
// Design Name: 
// Module Name: fifo_syn
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


interface fifo_bus();
    localparam DSIZE = 8;
    localparam DEPTH = 40;              // <-- set this to whatever depth you calculated
    localparam ASIZE = $clog2(DEPTH);   // pointer width (address bits)

    logic               Clock;
    logic               Reset;
    logic [DSIZE-1:0]   Data_in;
    logic               Write_en;
    logic [DSIZE-1:0]   Data_out;
    logic               Read_en;
    logic               Full;
    logic               Empty;

    modport dut(input  Clock, Reset, Data_in, Write_en, Read_en,
                output Data_out, Full, Empty);
endinterface


module fifo_syn(fifo_bus.dut bus);

    localparam DSIZE = 8;
    localparam DEPTH = 40;              
    localparam ASIZE = $clog2(DEPTH);

    integer i;

    // one extra bit on each pointer so we can tell full apart from empty
    logic [ASIZE:0] w_ptr, r_ptr;
    logic [DSIZE-1:0] mem [0:DEPTH-1];

    wire [ASIZE-1:0] w_addr = w_ptr[ASIZE-1:0];
    wire [ASIZE-1:0] r_addr = r_ptr[ASIZE-1:0];

    wire empty_i = (w_ptr == r_ptr);
    wire full_i  = (w_ptr[ASIZE]     != r_ptr[ASIZE]) &&
                   (w_ptr[ASIZE-1:0] == r_ptr[ASIZE-1:0]);

    assign bus.Empty = empty_i;
    assign bus.Full  = full_i;

    // write side
    always_ff @(posedge bus.Clock or posedge bus.Reset) begin
        if (bus.Reset) begin
            w_ptr <= '0;
            for (i = 0; i < DEPTH; i++)
                mem[i] <= '0;
        end else if (bus.Write_en && !full_i) begin
            mem[w_addr] <= bus.Data_in;
	    if (w_addr == DEPTH-1)
		    w_ptr <= {~w_ptr[ASIZE], {ASIZE{1'b0}}};
	    else
		    w_ptr <= w_ptr + 1'b1;
            //w_ptr       <= w_ptr + 1'b1;
        end
    end

    //  read side 
    always_ff @(posedge bus.Clock or posedge bus.Reset) begin
        if (bus.Reset)
            r_ptr <= '0;
        else if (bus.Read_en && !empty_i)
		if (r_addr == DEPTH-1)
		       	r_ptr <= {~r_ptr[ASIZE], {ASIZE{1'b0}}};
		else
			r_ptr <= r_ptr + 1'b1;
//r_ptr <= r_ptr + 1'b1;
    end

    // combinational "fall-through" read data
    assign bus.Data_out = (!empty_i) ? mem[r_addr] : {DSIZE{1'b0}};

endmodule





