`timescale 1ns / 1ps

module page_table(
    input wire read_write_PT,
    input wire [5:0] virtual_page_tag,
    input wire dirty_write_back,
    input wire reference_write_back,
    output reg [1:0] physical_page_tag,
    output reg page_fault,
    output reg PT_done,
    output reg dirty_fetched,
    output reg reference_fetched
    );

    reg [31:0] page_directory [63:0];

    integer entry_idx;

    initial begin
        #10
        PT_done = 1'b0;
        page_fault = 1'b0;
        physical_page_tag = 2'b0;
        dirty_fetched = 0;
        reference_fetched = 0;
        for (entry_idx = 0; entry_idx < 64; entry_idx = entry_idx + 1) begin
            page_directory[entry_idx] = 0;
        end
        page_directory[0] = {1'b1, 29'b0, 2'd1};
        page_directory[1] = {1'b1, 29'b0, 2'd3};
        page_directory[2] = {1'b0, 29'b0, 2'd2};
        page_directory[3] = {1'b1, 29'b0, 2'd3};
        page_directory[4] = {1'b1, 29'b0, 2'd2};
        page_directory[5] = 32'b0;
        page_directory[6] = 32'b0;
        page_directory[7] = {1'b1, 29'b0, 2'd1}; 
        page_directory[8] = {1'b1, 29'b0, 2'd1};
        page_directory[9] = 32'b0;
        page_directory[10] = {1'b1, 29'b0, 2'd1}; 
    end

    always @(*) begin
        #1
        if (read_write_PT == 1'b1) begin
            // Update dirty/reference bits when a write-back is requested
            page_directory[virtual_page_tag][3] = 1'b1;
            page_directory[virtual_page_tag][2] = 1'b1;
        end
        if (read_write_PT == 1'b0) begin
            if (page_directory[virtual_page_tag][31] == 1'b1) begin // Entry is valid, so not a page fault.
                physical_page_tag = page_directory[virtual_page_tag][1:0];
                dirty_fetched = page_directory[virtual_page_tag][3];
                reference_fetched = page_directory[virtual_page_tag][2];
                page_fault = 1'b0;
            end
            else begin
                page_fault = 1'b1;
            end
        end
        #1 PT_done = 1'b1;
        #1 PT_done = 1'b0;
    end

endmodule
