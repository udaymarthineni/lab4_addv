`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.09.2026 13:19:34
// Design Name: 
// Module Name: even_odd_alternating
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



interface eo_bus();
    localparam DSIZE = 8;

    logic             Clock;
    logic             Reset;
    logic [DSIZE-1:0] Data_in;
    logic             Write_en;
    logic [DSIZE-1:0] Data_out;
    logic             Read_en;

    
    modport dut(input  Clock, Reset, Data_in, Write_en, Read_en,
                output Data_out);

    modport tb (output Clock, Reset, Data_in, Write_en, Read_en,
                input  Data_out);

    // XMR 
    wire even_write = $root.tb.dut.even_bus.Write_en;
    wire odd_write  = $root.tb.dut.odd_bus.Write_en;
    wire even_read  = $root.tb.dut.even_en;
    wire odd_read   = $root.tb.dut.odd_en;
    wire turn_odd   = $root.tb.dut.state;

    wire selected_empty = turn_odd ? $root.tb.dut.odd_bus.Empty : $root.tb.dut.even_bus.Empty;
    wire [7:0] selected_data = even_read ? $root.tb.dut.even_bus.Data_out : $root.tb.dut.odd_bus.Data_out;

    // Assertions
    a1: assert property (@(posedge Clock) disable iff (Reset)
        (Write_en && !Data_in[0]) |-> (even_write && !odd_write));

    a2: assert property (@(posedge Clock) disable iff (Reset)
        (Write_en && Data_in[0]) |-> (odd_write && !even_write));

    a3: assert property (@(posedge Clock) disable iff (Reset)
        even_read |=> turn_odd);

    a4: assert property (@(posedge Clock) disable iff (Reset)
        odd_read |=> !turn_odd);

    a5: assert property (@(posedge Clock) disable iff (Reset)
        (even_read || odd_read) |=> (Data_out == $past(selected_data)));

//    a6: assert property (@(posedge Clock) disable iff (Reset)
  //      selected_empty |-> (!even_read && !odd_read) ##1 $stable(turn_odd));

    a7: assert property (@(posedge Clock) disable iff (Reset)
        (!even_read && !odd_read) |=> $stable(Data_out));

endinterface


module even_odd_alternating(eo_bus.dut bus);

   
    fifo_bus even_bus();
    fifo_bus odd_bus();

    fifo_syn even_fifo(.bus(even_bus));
    fifo_syn odd_fifo (.bus(odd_bus));

    assign even_bus.Clock = bus.Clock;
    assign even_bus.Reset = bus.Reset;
    assign odd_bus.Clock  = bus.Clock;
    assign odd_bus.Reset  = bus.Reset;

    // write side  logic
    assign even_bus.Data_in = bus.Data_in;
    assign odd_bus.Data_in  = bus.Data_in;

    assign even_bus.Write_en = bus.Write_en && (bus.Data_in[0] == 1'b0); // LSB=0 -> even
    assign odd_bus.Write_en  = bus.Write_en && (bus.Data_in[0] == 1'b1); // LSB=1 -> odd

    //   2-state FSM 
    typedef enum logic {TURN_EVEN, TURN_ODD} state_t;
    state_t state, next_state;
    
    // read side logic
    always_ff @(posedge bus.Clock or posedge bus.Reset) begin
        if (bus.Reset)
            state <= TURN_EVEN;      
        else
            state <= next_state;
    end

    //error added when +EO_BUG 
    bit inject_error;
    initial begin
        inject_error = $test$plusargs("EO_BUG");
        if (inject_error)
            $display("EO_BUG enabled: even read data bit 0 will be flipped");
    end

    logic even_en, odd_en;

    always_comb begin
        next_state = state;
        even_en   = 1'b0;
        odd_en    = 1'b0;

        case (state)
            TURN_EVEN: begin
                if (bus.Read_en && !even_bus.Empty) begin
                    even_en   = 1'b1;
                    next_state = TURN_ODD;
                end
                // else: even FIFO empty or no read requested -> stall, stay TURN_EVEN
            end

            TURN_ODD: begin
                if (bus.Read_en && !odd_bus.Empty) begin
                    odd_en    = 1'b1;
                    next_state = TURN_EVEN;
                end
            end
        endcase
    end

    assign even_bus.Read_en = even_en;
    assign odd_bus.Read_en  = odd_en;

    // ---------------- Data_out: registered, holds last value when idle ----------------
    always_ff @(posedge bus.Clock or posedge bus.Reset) begin
        if (bus.Reset)
            bus.Data_out <= 8'h00;
        else if (even_en) begin
            if (inject_error)
                bus.Data_out <= even_bus.Data_out ^ 8'h01; // Fault injection
            else
                bus.Data_out <= even_bus.Data_out;
        end
        else if (odd_en)
            bus.Data_out <= odd_bus.Data_out;
        // else: hold previous Data_out
    end

endmodule
