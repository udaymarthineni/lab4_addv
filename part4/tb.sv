`timescale 1ns / 1ps
module tb;
    eo_bus bus();
    even_odd_alternating dut(bus);
    integer read_count;

    initial begin
        if ($test$plusargs("EO_BUG"))
            $fsdbDumpfile("eo_bug.fsdb");
        else
            $fsdbDumpfile("eo_clean.fsdb");
        $fsdbDumpvars(0, tb);
        $fsdbDumpSVA(0, tb);
    end

    initial begin
	    bus.Clock = 0;
	    forever #5 bus.Clock = ~bus.Clock;
    end

    always @(posedge bus.Clock) begin
	    if (bus.Reset) begin
            read_count = 0;
        end
        else begin
		if (bus.Write_en) begin
			if (bus.Data_in[0] == 1'b0)
				$display("TIME=%0t  WRITE EVEN  Data=%0d",$time, bus.Data_in);
			else
				$display("TIME=%0t  WRITE ODD   Data=%0d",$time, bus.Data_in);
	       	end
		if (dut.even_en) begin
			read_count = read_count + 1;
			$display("TIME=%0t  READ EVEN   Data=%0d  ReadCount=%0d",$time, dut.even_bus.Data_out,read_count);
		end
		else if (dut.odd_en) begin
			read_count = read_count + 1;
			$display("TIME=%0t  READ ODD    Data=%0d  ReadCount=%0d",$time, dut.odd_bus.Data_out, read_count);
		end
		else if (bus.Read_en) begin
			$display("TIME=%0t  STALLED  Data_out=%0d  EvenEmpty=%b  OddEmpty=%b",$time, bus.Data_out, dut.even_bus.Empty, dut.odd_bus.Empty);
		end
	end
end
initial begin
	
	integer i;
        integer j;

        bus.Reset    = 1;
        bus.Write_en = 0;
        bus.Read_en  = 0;
        bus.Data_in  = 0;
        
        repeat(2) @(posedge bus.Clock);
       	@(negedge bus.Clock);
        bus.Reset = 0;

        // CASE 1

        $display("CASE 1: FIRST 80 WRITE, LAST 20 IDLE");
	//first 40 even ,next 40 odd.
        for (i = 0; i < 100; i++) begin 
		@(negedge bus.Clock);	
		if (i < 80) begin
			bus.Write_en = 1'b1;
			if (i < 40)
				bus.Data_in = 2*(i) + 2;
			else
				bus.Data_in = 2*(i-40) + 1;
		end
		else begin
			bus.Write_en = 1'b0;
		end
		if ((i % 10) < 8)
			bus.Read_en = 1'b1;
		else
			bus.Read_en = 1'b0;
	end
	//continue reads till read are 80
	j = 0;
        while (read_count < 80) begin
            @(negedge bus.Clock);
            bus.Write_en = 1'b0;
            if (read_count < 80) begin
                if ((j % 10) < 8)
                    bus.Read_en = 1'b1;
                else
                    bus.Read_en = 1'b0;
                j = j + 1;
            end
            else begin
                bus.Read_en = 1'b0;
            end
        end
        bus.Read_en = 1'b0;
        $display("CASE 1 COMPLETE: 80 SUCCESSFUL READS");

        @(negedge bus.Clock);
        bus.Reset    = 1'b1;
        bus.Write_en = 1'b0;
        bus.Read_en  = 1'b0;
        repeat(2) @(posedge bus.Clock);
        @(negedge bus.Clock);
        bus.Reset = 1'b0;

	 // CASE 2


        $display("CASE 2: FIRST 20 IDLE, LAST 80 WRITE");
	for (i = 0; i < 100; i++) begin
            @(negedge bus.Clock);
            if (i < 20) begin
    		    bus.Write_en = 1'b0;
    	    end
            else begin
                bus.Write_en = 1'b1;
                if (i < 60)
                    bus.Data_in = 2*(i-20) + 1;
                else
                    bus.Data_in = 2*(i-60) + 2;
            end

            if ((i % 10) < 8)
		    bus.Read_en = 1'b1;
            else
		    bus.Read_en = 1'b0;
    end

        j = 0;
        while (read_count < 80) begin
            @(negedge bus.Clock);
            bus.Write_en = 1'b0;
            if (read_count < 80) begin
		 if ((j % 10) < 8)
                    	bus.Read_en = 1'b1;
		else
                    	bus.Read_en = 1'b0;
                	j = j + 1;
		end
            else begin
                bus.Read_en = 1'b0;
            end
        end

        bus.Read_en = 1'b0;

        $display("CASE 2 COMPLETE: 80 SUCCESSFUL READS");

        repeat(2) @(posedge bus.Clock);
        $finish;
    end
endmodule
