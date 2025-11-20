`timescale 1ns / 1ps

module translation_look_aside_buffer(
    input wire [13:0] virtual_address, // From CPU
    input wire input_read_write, // 1'b0 for read data, lw; 1'b1 for write data, sw; // From CPU
    input wire [1:0] physical_page_tag, // From PT
    input wire PT_done, // From PT
    input wire page_fault,
    input wire dirty_fetched,
    input wire reference_fetched,
    output reg[9:0] physical_address, // to Cache
    output wire output_read_write, // to Cache, 1'b0 for read data, 1'b1 for write data. 
    output reg[5:0] virtual_page_tag, // to PT
    output reg PA_done, // to Cache
    output reg read_write_PT,
    output reg dirty_write_back,
    output reg reference_write_back
    );

    parameter ENTRY_COUNT = 4; // Four entries in our fully-associative TLB
    parameter VIRTUAL_OFFSET_BITS = 8; // Number of bits consumed by page offset

    wire [5:0] current_vpn;
    wire [VIRTUAL_OFFSET_BITS:0] page_offset;
    reg [5:0] vpn_tags [ENTRY_COUNT-1:0];
    reg slot_valid [ENTRY_COUNT-1:0];
    reg slot_dirty [ENTRY_COUNT-1:0];
    reg slot_reference [ENTRY_COUNT-1:0];
    reg [1:0] frame_ids [ENTRY_COUNT-1:0]; // Physical frame stored in each slot
    reg [1:0] usage_ranks [ENTRY_COUNT-1:0]; // Small counter that tracks LRU order
    reg lookup_hit;
    wire match_slot_0;
    wire match_slot_1;
    wire match_slot_2;
    wire match_slot_3;
    wire hit_slot_0;
    wire hit_slot_1;
    wire hit_slot_2;
    wire hit_slot_3;

    integer scan_idx, chosen_slot, adjust_idx;
    initial begin
        #10;
        physical_address = 0;
        virtual_page_tag = 0;
        PA_done = 0;
        read_write_PT = 0;
        dirty_write_back = 0;
        reference_write_back = 0;
        for (scan_idx = 0; scan_idx < ENTRY_COUNT; scan_idx = scan_idx + 1) begin
            vpn_tags[scan_idx] = 0;
            slot_valid[scan_idx] = 0;
            slot_dirty[scan_idx] = 0;
            slot_reference[scan_idx] = 0;
            frame_ids[scan_idx] = 0;
        end
        usage_ranks[0] = 2'b11;
        usage_ranks[1] = 2'b10;
        usage_ranks[2] = 2'b01;
        usage_ranks[3] = 2'b00;

    end

    assign output_read_write = input_read_write;
    assign current_vpn = virtual_address[13:8];
    assign page_offset = virtual_address[VIRTUAL_OFFSET_BITS:0];
    assign match_slot_0 = (current_vpn == vpn_tags[0]);
    assign match_slot_1 = (current_vpn == vpn_tags[1]);
    assign match_slot_2 = (current_vpn == vpn_tags[2]);
    assign match_slot_3 = (current_vpn == vpn_tags[3]);

    assign hit_slot_0 = slot_valid[0] & match_slot_0;
    assign hit_slot_1 = slot_valid[1] & match_slot_1;
    assign hit_slot_2 = slot_valid[2] & match_slot_2;
    assign hit_slot_3 = slot_valid[3] & match_slot_3;

    always @(*) begin
        lookup_hit = hit_slot_0 | hit_slot_1 | hit_slot_2 | hit_slot_3;

        if (!lookup_hit) begin // Miss: we send request to page table and potentially write back eviction
            PA_done = 1'b0;
            for (scan_idx = 0; scan_idx < ENTRY_COUNT; scan_idx = scan_idx + 1) begin
                if (usage_ranks[scan_idx] == 2'b11) begin
                    // Evict the least recently used entry first, handling dirty/ reference bits via PT write request.
                    if (slot_dirty[scan_idx]) begin
                        virtual_page_tag = current_vpn;
                        dirty_write_back = slot_dirty[scan_idx];
                        reference_write_back = slot_reference[scan_idx];
                        read_write_PT = 1'b1;
                    end

                    read_write_PT = 1'b0; // Read latest translation
                    virtual_page_tag = current_vpn;
                    #1

                    if (!page_fault) begin
                        if (PT_done) begin
                            vpn_tags[scan_idx] = current_vpn;
                            frame_ids[scan_idx] = physical_page_tag;
                            slot_dirty[scan_idx] = dirty_fetched;
                            slot_reference[scan_idx] = reference_fetched;
                        end

                        slot_valid[scan_idx] = 1'b1;
                        slot_reference[scan_idx] = 1'b1;
                        if (input_read_write) begin
                            slot_dirty[scan_idx] = 1'b1;
                        end
                    end
                end
            end
        end
        else begin // Hit: compose physical address and refresh LRU counters
            read_write_PT = 1'b0;
            virtual_page_tag = current_vpn;
            #1
            physical_address[VIRTUAL_OFFSET_BITS-1:0] = page_offset;
            if (hit_slot_0) begin
                physical_address[9:8] = frame_ids[0];
                chosen_slot = 0;
            end
            else if (hit_slot_1) begin
                physical_address[9:8] = frame_ids[1];
                chosen_slot = 1;
            end
            else if (hit_slot_2) begin
                physical_address[9:8] = frame_ids[2];
                chosen_slot = 2;
            end
            else begin // hit_slot_3 must be true here
                physical_address[9:8] = frame_ids[3];
                chosen_slot = 3;
            end
            PA_done = 1'b1;
            // Increase rank of other entries, then push this entry to most-recently-used
            for (adjust_idx = 0; adjust_idx < ENTRY_COUNT; adjust_idx = adjust_idx + 1) begin
                if (usage_ranks[adjust_idx] < usage_ranks[chosen_slot]) begin 
                    usage_ranks[adjust_idx] = usage_ranks[adjust_idx] + 2'b01;
                end
            end
            usage_ranks[chosen_slot] = 2'b00;

            if (input_read_write) begin
                slot_dirty[chosen_slot] = 1'b1;
            end
        end
    end

endmodule
