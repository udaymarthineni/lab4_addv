`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  
// Engineer: 
// 
// Create Date: 19.09.2026 11:52:25
// Design Name: 
// Module Name: fifo_tb
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


`define W2FIFO(w_data)     \
    begin                   \
    bus.winc = 1'b1;            \
    bus.wdata = w_data;         \
    wait(bus.wclk == 1'b1);      \
    wait(bus.wclk == 1'b0);      \
    bus.winc = 1'b0;             \
    end
    
    `define R2FIFO     \
    begin                   \
    bus.rinc = 1'b1;            \
    wait(bus.rclk == 1'b1);      \
    wait(bus.rclk == 1'b0);      \
    bus.rinc = 1'b0;             \
    end
    
 `define CHECK_FULL     \
    begin               \
    if(bus.wfull == 1'b1)  \
    $display("the fifo is full");   \
     else                       \
     $display("the fifo is not full");  \
    end
    
    `define CHECK_ALMOST_FULL     \
    begin               \
    if(bus.almost_wfull == 1'b1)  \
    $display("the fifo is almost full");   \
     else                       \
     $display("the fifo is not almost full");  \
    end
    
    `define CHECK_EMPTY     \
    begin               \
    if(bus.rempty == 1'b1)  \
    $display("the fifo is empty");   \
     else                       \
     $display("the fifo is not empty");  \
    end
    

    `define SIMULT_RD_WR(data)    \
    begin   \
    bus.winc = 1'b1;                \
    bus.rinc = 1'b1;                \
    bus.wdata = data;             \
    wait(bus.rclk == 1'b1);     \
    wait(bus.rclk == 1'b0);     \
    wait(bus.wclk == 1'b1);     \
    wait(bus.wclk == 1'b0);     \
    bus.winc =1'b0;         \
    bus.rinc =1'b0;         \
    end    
   /*         
    `define VAL_MEM(i)  \
         $display("The value in fifo at %h is %h ",dut.wptr_full.wptr ,dut.fifomem.mem[i]);  
             
     */
     
module fifo_tb();
fifo1_bus bus();

parameter DSIZE = 8;
parameter ASIZE = 4;

 logic i;
 logic [ASIZE :0] rptr;
 logic [ASIZE :0] wptr;
 
fifo1 
dut ( .bus(bus)
  );

// Part 2: DPI-C reference checker.
fifo_checker checker(.bus(bus));
  
initial begin
    $fsdbDumpfile("novas.fsdb");
    $fsdbDumpvars(0, fifo_tb);
end 
  
  

assign rptr = dut.rptr_empty.rptr;
assign wptr = dut.wptr_full.wptr;

always
    begin
    bus.wclk = 1'b0;
    #5
    bus.wclk = 1'b1;
    #5;
    end

always
    begin
    bus.rclk = 1'b0;
    #10
    bus.rclk = 1'b1;
    #10;
    end
        
initial 
    begin
    bus.winc =1'b0;
    bus.rinc = 1'b0;
    
    bus.wrst_n = 1'b0;
    bus.rrst_n = 1'b0;
    
     wait(bus.rclk == 1'b1);
    wait(bus.rclk == 1'b0);
     wait(bus.rclk == 1'b1);
    wait(bus.rclk == 1'b0);
     bus.rrst_n = 1'b1;
     
      wait(bus.wclk == 1'b1);
    wait(bus.wclk == 1'b0);
     wait(bus.wclk == 1'b1);
    wait(bus.wclk == 1'b0);
     bus.wrst_n = 1'b1;
    
    
  
  /*  
    
    
    // rrst_n = 1'b1;
  $display("the value of the write ptr is %d ", dut.wptr_full.wptr);
 `W2FIFO (8'h01)
 $display("the value of the write ptr is %d ", dut.wptr_full.wptr);
 `W2FIFO (8'h02)
 $display("the value of the write ptr is %d ", dut.wptr_full.wptr);
 `W2FIFO (8'h03)
 $display("the value of the write ptr is %d ", dut.wptr_full.wptr);
 `W2FIFO (8'h04)
 $display("the value of the write ptr is %d ", dut.wptr_full.wptr);
 //`W2FIFO (8'h05)
 //$display("the value of the write ptr is %d ", dut.wptr_full.wptr);
 `W2FIFO (8'h06)    
 //$display("the value of the write ptr is %d ", dut.wptr_full.wptr);
 
 // $display("The value in fifo 2nd row is %h ", dut.fifomem.mem[2]);
 
 */
 //ALMOST FULL CHECK CONDITION
 
 `W2FIFO (8'h00)
 //`VAL_MEM(0)
 
 `W2FIFO (8'h01)
 //`VAL_MEM(1)
 `W2FIFO (8'h02)
 //`VAL_MEM(2)
 `W2FIFO (8'h03)
 wait(bus.wclk == 1'b1);
 wait(bus.wclk == 1'b0);
 `W2FIFO (8'h04)
 wait(bus.wclk == 1'b1);
 wait(bus.wclk == 1'b0);

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
 `W2FIFO (8'h07)
     
 
 
  
          //  $display("the value of the read ptr is %d ", dut.rptr_empty.rptr);
           // $display("the value of the write ptr is %d ", dut.wptr_full.wptr);
   
   wait(bus.wclk == 1'b1);
 wait(bus.wclk == 1'b0);
    
   wait(bus.wclk == 1'b1);
 wait(bus.wclk == 1'b0);
    
    wait(bus.wclk == 1'b1);
 wait(bus.wclk == 1'b0);
    
    
 // fifo full should be checked
  `CHECK_FULL
    
     wait(bus.rclk == 1'b1);
     wait(bus.rclk == 1'b0);
    
    // rrst_n = 1'b1;
    
      wait(bus.rclk == 1'b1);
     wait(bus.rclk == 1'b0);
     
   
    
    `R2FIFO
    `R2FIFO
    `R2FIFO
    `R2FIFO
    `R2FIFO
    `R2FIFO
    `R2FIFO
    `R2FIFO
    `R2FIFO
    `R2FIFO
    `R2FIFO
    `R2FIFO
    `R2FIFO
    `R2FIFO
    `R2FIFO
    `R2FIFO
    
   `CHECK_EMPTY
   
     wait(bus.wclk == 1'b1);
 wait(bus.wclk == 1'b0);
 
     wait(bus.wclk == 1'b1);
 wait(bus.wclk == 1'b0);
    
     wait(bus.rclk == 1'b1);
     wait(bus.rclk == 1'b0);
    `CHECK_EMPTY
    
    `W2FIFO (8'h0d)
 `W2FIFO (8'h0e)
 `W2FIFO (8'h0f)
 `W2FIFO (8'h07)
    
    `SIMULT_RD_WR(8'h04)
    `SIMULT_RD_WR(8'h05)
    `SIMULT_RD_WR(8'h06)
    `SIMULT_RD_WR(8'h07)
    
    
    bus.rinc = 1'b1;
    
     wait(bus.rclk == 1'b1);
     wait(bus.rclk == 1'b0);
     
      wait(bus.rclk == 1'b1);
     wait(bus.rclk == 1'b0);
    
     wait(bus.rclk == 1'b1);
     wait(bus.rclk == 1'b0);
    
     wait(bus.rclk == 1'b1);
     wait(bus.rclk == 1'b0);
     
     wait(bus.rclk == 1'b1);
     wait(bus.rclk == 1'b0);
    
     wait(bus.rclk == 1'b1);
     wait(bus.rclk == 1'b0);
     
     wait(bus.rclk == 1'b1);
     wait(bus.rclk == 1'b0);
    
      wait(bus.rclk == 1'b1);
     wait(bus.rclk == 1'b0);
    
    bus.rinc = 1'b0; 

    #20;
    $display("FIFO TEST COMPLETED");
    $finish;

    end
    
    


endmodule
