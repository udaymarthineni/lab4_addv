`timescale 1ns / 1ps
module fifo_checker(fifo1_bus bus);

    import fifo_dpi_pkg::*;
    int expected_data;
    int model_full, model_empty;

    int writes = 0, reads = 0, errors = 0;
    int full_checks = 0, empty_checks = 0;
    int wclks_since_read = 0;
    int rclks_since_write = 0;

    int head_data;
    int model_almost_full, model_almost_empty;
    int almost_full_checks = 0;
    int almost_empty_checks = 0;
    int fwft_checks = 0;
    int fwft_idle_checks = 0;

    initial fifo_init();

    always @(negedge bus.wrst_n or negedge bus.rrst_n) begin
        fifo_init();
        wclks_since_read = 0;
        rclks_since_write = 0;
    end

    //Update C model when DUT accepts a write
    always @(posedge bus.wclk) begin
        if (bus.wrst_n && bus.rrst_n) begin
            wclks_since_read++;
            if (bus.winc && !bus.wfull) begin
                if (fifo_push(int'(bus.wdata)) != 1) begin
                    errors++;
                    $error("C model rejected write");
                end
                writes++;
                rclks_since_write = 0;
            end
        end
    end

    //Check full and almost full flag every write cycle
    always @(negedge bus.wclk) begin
        if (bus.wrst_n && bus.rrst_n) begin
            model_full = fifo_is_full();
            full_checks++;
            if (bus.wfull !== model_full[0]) begin
                if (model_full || wclks_since_read >= 4) begin
                    errors++;
                    $error("FULL mismatch: model=%0d DUT=%0b",model_full, bus.wfull);
                end
            end
            model_almost_full = fifo_is_almost_full();
            almost_full_checks++;
            if (bus.almost_wfull === 1'b1 && fifo_get_count() > 12) begin
                errors++;
                $error("ALMOST_FULL asserted above 12 entries");
            end
            else if (wclks_since_read >= 4 &&
                     bus.almost_wfull !== model_almost_full[0]) begin
                errors++;
                $error("ALMOST_FULL mismatch: model=%0d DUT=%0b",model_almost_full, bus.almost_wfull);
            end
        end
    end


    //Compare DUT data with C model
    always @(posedge bus.rclk) begin
        if (bus.wrst_n && bus.rrst_n) begin
            rclks_since_write++;
            if (bus.rinc && !bus.rempty) begin
                expected_data = fifo_pop();
                if (expected_data == -1 ||bus.rdata !== expected_data[7:0]) begin
                    errors++;
                    $error("READ mismatch: expected=%0h DUT=%0h",expected_data, bus.rdata);
                end
                reads++;
                wclks_since_read = 0;
            end
        end
    end





    // 4. check emoty, almost empty and output zero
    always @(negedge bus.rclk) begin
        if (bus.wrst_n && bus.rrst_n) begin
            model_empty = fifo_is_empty();
            empty_checks++;
            if (bus.rempty !== model_empty[0]) begin
                if (model_empty || rclks_since_write >= 4) begin
                    errors++;
                    $error("EMPTY mismatch: model=%0d DUT=%0b",model_empty, bus.rempty);
                end
            end
            model_almost_empty = fifo_is_almost_empty();
            almost_empty_checks++;
            if (bus.almost_rempty === 1'b1 && fifo_get_count() < 4) begin
                errors++;
                $error("ALMOST_EMPTY asserted below 4 entries");
            end
            else if (rclks_since_write >= 4 &&
                     bus.almost_rempty !== model_almost_empty[0]) begin
                errors++;
                $error("ALMOST_EMPTY mismatch: model=%0d DUT=%0b",model_almost_empty, bus.almost_rempty);
            end
            if (!bus.rempty) begin
                head_data = fifo_peek();
                fwft_checks++;
                if (!bus.rinc)
                    fwft_idle_checks++;
                if (head_data == -1 || bus.rdata !== head_data[7:0]) begin
                    errors++;
                    $error("FWFT mismatch: expected=%0h DUT=%0h",head_data, bus.rdata);
                end
            end
        end
    end

final begin
    $display("DPI CHECKER: writes=%0d reads=%0d full_checks=%0d empty_checks=%0d almost_full_checks=%0d almost_empty_checks=%0d fwft_checks=%0d fwft_idle_checks=%0d errors=%0d",writes, reads, full_checks, empty_checks,almost_full_checks, almost_empty_checks,fwft_checks, fwft_idle_checks, errors);
end
endmodule
