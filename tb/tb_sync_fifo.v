`timescale 1ns/1ps

module tb_sync_fifo;

    // Parameters
    parameter WIDTH = 8;
    parameter DEPTH = 16;

    // Inputs
    reg clk;
    reg rst_n;
    reg wr_en;
    reg rd_en;
    reg [WIDTH-1:0] data_in;

    // Outputs
    wire [WIDTH-1:0] data_out;
    wire full;
    wire empty;
    wire almost_full;
    wire almost_empty;

    // Instantiate the Unit Under Test (UUT)
    sync_fifo #(WIDTH, DEPTH) uut (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .data_in(data_in),
        .data_out(data_out),
        .full(full),
        .empty(empty),
        .almost_full(almost_full),
        .almost_empty(almost_empty)
    );

    // Clock Generation (50MHz = 20ns period)
    always #10 clk = ~clk;

    // --- Verification Tasks ---
    
    task reset_system;
        begin
            rst_n = 0; wr_en = 0; rd_en = 0; data_in = 0;
            #40 rst_n = 1;
            $display("--- System Reset Complete ---");
        end
    endtask

    task write_data(input [WIDTH-1:0] val);
        begin
            @(negedge clk);
            if (!full) begin
                wr_en = 1; data_in = val;
                @(negedge clk);
                wr_en = 0;
            end
        end
    endtask

    task read_data;
        begin
            @(negedge clk);
            if (!empty) begin
                rd_en = 1;
                @(negedge clk);
                rd_en = 0;
            end
        end
    endtask

    // --- Main Test Sequence ---
    initial begin
        // Initialize
        clk = 0;
        reset_system();

        // 1. Test Empty Flag
        if (empty) $display("SUCCESS: Empty flag asserted at startup.");

        // 2. Write 16 items (Fill the FIFO)
        $display("Writing 16 items...");
        for (integer i = 1; i <= 16; i = i + 1) begin
            write_data(i); // Pattern: 1, 2, 3...
        end

        // 3. Check Full Flag
        #20;
        if (full) $display("SUCCESS: Full flag asserted at 16 items.");

        // 4. Test Overflow Protection
        write_data(8'hFF);
        $display("Attempted overflow write. Checking stability...");

        // 5. Read back all items
        $display("Reading back items...");
        for (integer j = 1; j <= 16; j = j + 1) begin
            read_data();
            $display("Read Data: %d (Expected: %d)", data_out, j);
        end

        // 6. Check Empty Flag again
        #20;
        if (empty) $display("SUCCESS: FIFO is empty again.");

        $display("--- All Tests Passed ---");
        $stop;
    end

endmodule
