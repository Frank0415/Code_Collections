`timescale 1ns / 1ps

module associative_back_cache(
    input wire read_write_cache,  // 1'b1 write, 1'b0 read.
    input wire [9:0] address_cache,
    input wire[31:0] write_data_cache, // From TLB physical address. 
    input wire done,
    input wire PA_done, // From TLB
    input wire [31:0] read_data_mem,
    output reg [31:0] read_data_cache,
    output wire hit_miss,
    output reg read_write_mem,
    output reg [9:0] address_mem,
    output reg [31:0] write_data_mem
    );

    parameter set_index = 2; // 64 bytes = 16 words = 4 blocks * (4 words per block) = 2 sets * (2 blocks per set) * (4 words per block)
    parameter block_width = 2;
    parameter block_index = 4;
    parameter Tag_size = 5; // Address - Byte_offset - Word_offset - set_index = 10 - 2 - 2 - 1.
    parameter cache_width = 135; // Valid + Dirty + Tag_size + 4 * word_width.

    wire way0_valid, way1_valid;
    wire way0_dirty, way1_dirty;
    wire [Tag_size-1:0] way0_tag, way1_tag;
    wire active_set;
    wire [cache_width-1:0] way0_line, way1_line;
    wire way0_tag_match, way1_tag_match;
    wire way0_hit, way1_hit;
    wire [1:0] byte_offset_select;
    wire [1:0] word_offset_select;
    // The cache is organized as 2 sets * 2 ways, each line packing valid, dirty, tag, and four words.
    reg [cache_width-1:0] line_storage [block_index-1:0]; // 4 lines total
    reg line_valid [block_index-1:0]; 
    reg line_dirty [block_index-1:0]; 
    reg [Tag_size-1:0] line_tag [block_index-1:0]; // 4 tags, each 5 bits.
    reg lru_state [set_index-1:0]; // LRU bit per set indicates least recently used way

    integer i;
    initial begin
        read_write_mem = 0;
        address_mem = 0;
        write_data_mem = 0;
        for (i = 0; i < set_index; i = i + 1) begin
            lru_state[i] = 0;
        end
        for (i = 0; i < block_index; i = i + 1) begin
            line_storage[i] = 0;
            line_valid[i] = 0;
            line_dirty[i] = 0;
            line_tag[i] = 0;
        end
    end

    assign active_set = address_cache[4];
    assign way0_line = line_storage[{active_set,1'b0}]; // Set selects which pair of lines to read.
    assign way1_line = line_storage[{active_set,1'b1}];
    assign way0_valid = way0_line[cache_width-1];
    assign way1_valid = way1_line[cache_width-1];
    assign way0_dirty = way0_line[cache_width-2];
    assign way1_dirty = way1_line[cache_width-2];
    assign way0_tag = way0_line[cache_width-3 : cache_width-7];
    assign way1_tag = way1_line[cache_width-3 : cache_width-7];
    assign way0_tag_match = (way0_tag == address_cache[9:5]);
    assign way1_tag_match = (way1_tag == address_cache[9:5]);
    assign word_offset_select = address_cache[3:2];
    assign byte_offset_select = address_cache[1:0];
    and(way0_hit, way0_valid, way0_tag_match); // Hit requires valid bit and tag equality.
    and(way1_hit, way1_valid, way1_tag_match);
    or(hit_miss, way0_hit, way1_hit);

    always @(*) begin
        #2
        if (PA_done) begin // TLB has complete the translation from VA to PA.
        // if (Valid & isTag) hit_miss = 1;
            if(read_write_cache) begin // This is a write in instruction. sw
                if (hit_miss) begin // There is data in the cache now. Then just write in the data. 
                    if (hit_A) begin             
                        // block A is the required position.   
                        if(Byte_offset == 2'b00) begin // sw
                            case (Word_offset)
                                2'b00: block[{setIndex,1'b0}][127:96] = write_data_cache;
                                2'b01: block[{setIndex,1'b0}][95:64] = write_data_cache;
                                2'b10: block[{setIndex,1'b0}][63:32] = write_data_cache;
                                2'b11: block[{setIndex,1'b0}][31:0] = write_data_cache;
                                default: block[{setIndex,1'b0}] = 0;
                            endcase
                        end
                        else begin // sb
                            i = 127 - 32 * Word_offset - 8 * (3-Byte_offset);
                            block[{setIndex,1'b0}][i-:8] = write_data_cache;
                        end
                        block[{setIndex,1'b0}][cache_width-2] = 1'b1; // Set Dirty bit to dirty. 
                        dirty[{setIndex,1'b0}] = 1'b1;
                        LRU[setIndex] = 1'b1;
                    end
                    else if (hit_B) begin
                        if (Byte_offset == 2'b00) begin
                            case (Word_offset)
                                2'b00: block[{setIndex,1'b1}][127:96] = write_data_cache;
                                2'b01: block[{setIndex,1'b1}][95:64] = write_data_cache;
                                2'b10: block[{setIndex,1'b1}][63:32] = write_data_cache;
                                2'b11: block[{setIndex,1'b1}][31:0] = write_data_cache;
                                default: block[{setIndex,1'b1}] = 0;
                            endcase
                        end
                        else begin
                            i = 127 - 32 * Word_offset - 8 * (3-Byte_offset);
                            block[{setIndex,1'b1}][i-:8] = write_data_cache;
                        end
                        block[{setIndex,1'b1}][cache_width-2] = 1'b1; // Set Dirty bit to dirty. 
                        dirty[{setIndex,1'b1}] = 1'b1;
                        LRU[setIndex] = 1'b0;
                    end
                end

                else if (!hit_miss) begin
                    if (LRU[setIndex] == 1'b0) begin
                        if (Dirty_A) begin // Need to write back to Main Memory first, then change the cache. 
                            read_write_mem = 1'b1; // Write to main memory. 
                            address_mem = {{Tag_A, setIndex}, {4{1'b0}}}; // Start from word0.
                            for (i = 0; i < 4; i = i + 1) begin
                                // address_mem = {Tag, blockIndex, i[1:0]};
                                case (i)
                                    0: write_data_mem = block_A[127:96];
                                    1: write_data_mem = block_A[95:64];
                                    2: write_data_mem = block_A[63:32];
                                    3: write_data_mem = block_A[31:0];
                                    default: write_data_mem = 32'b0;
                                endcase
                                @(posedge done) begin
                                    address_mem = address_mem + 4;
                                end
                            end
                            #7;
                        end

                        // Now read from main memory
                        read_write_mem = 1'b0; // Read from main memory.
                        address_mem = {address_cache[9:4], {4{1'b0}}};
                        for (i = 0; i < 4; i = i + 1) begin
                            @(posedge done) begin
                                case (i)
                                    0: block[{setIndex,1'b0}][127:96] = read_data_mem;
                                    1: block[{setIndex,1'b0}][95:64] = read_data_mem;
                                    2: block[{setIndex,1'b0}][63:32] = read_data_mem;
                                    3: block[{setIndex,1'b0}][31:0] = read_data_mem;
                                    default: block[{setIndex,1'b0}] = 0;
                                endcase
                                address_mem = address_mem + 4;
                            end
                        end

                        block[{setIndex,1'b0}][cache_width-1] = 1'b1; //  Set Valid bit = 1.
                        valid[{setIndex,1'b0}] = 1'b1;
                        block[{setIndex,1'b0}][cache_width-2] = 1'b1; // Set Dirty bit = 1.
                        dirty[{setIndex,1'b0}] = 1'b1;
                        block[{setIndex,1'b0}][cache_width-3:cache_width-7] = address_cache[9:5]; // Update the tag. 
                        tag[{setIndex,1'b0}] = address_cache[9:5];
                        LRU[setIndex] = 1'b1;

                        if(Byte_offset == 2'b00) begin // sw
                            case (Word_offset)
                                2'b00: block[{setIndex,1'b0}][127:96] = write_data_cache;
                                2'b01: block[{setIndex,1'b0}][95:64] = write_data_cache;
                                2'b10: block[{setIndex,1'b0}][63:32] = write_data_cache;
                                2'b11: block[{setIndex,1'b0}][31:0] = write_data_cache;
                                default: block[{setIndex,1'b0}] = 0;
                            endcase
                        end
                        else begin // sb
                            i = 127 - 32 * Word_offset - 8 * (3-Byte_offset);
                            block[{setIndex,1'b0}][i-:8] = write_data_cache;
                        end                   
                    end
                    else begin
                        if (Dirty_B) begin // Need to write back to Main Memory first, then change the cache. 
                            read_write_mem = 1'b1; // Write to main memory. 
                            address_mem = {{Tag_B, setIndex}, {4{1'b0}}}; // Start from word0.
                            for (i = 0; i < 4; i = i + 1) begin
                                // address_mem = {Tag, blockIndex, i[1:0]};
                                case (i)
                                    0: write_data_mem = block_B[127:96];
                                    1: write_data_mem = block_B[95:64];
                                    2: write_data_mem = block_B[63:32];
                                    3: write_data_mem = block_B[31:0];
                                    default: write_data_mem = 32'b0;
                                endcase
                                @(posedge done) begin
                                    address_mem = address_mem + 4;
                                end
                            end
                            #7;
                        end

                        // Now read from main memory
                        read_write_mem = 1'b0; // Read from main memory.
                        address_mem = {address_cache[9:4], {4{1'b0}}};
                        for (i = 0; i < 4; i = i + 1) begin
                            @(posedge done) begin
                                case (i)
                                    0: block[{setIndex,1'b1}][127:96] = read_data_mem;
                                    1: block[{setIndex,1'b1}][95:64] = read_data_mem;
                                    2: block[{setIndex,1'b1}][63:32] = read_data_mem;
                                    3: block[{setIndex,1'b1}][31:0] = read_data_mem;
                                    default: block[{setIndex,1'b1}] = 0;
                                endcase
                                address_mem = address_mem + 4;
                            end
                        end

                        block[{setIndex,1'b1}][cache_width-1] = 1'b1; //  Set Valid bit = 1.
                        valid[{setIndex,1'b1}] = 1'b1;
                        block[{setIndex,1'b1}][cache_width-2] = 1'b1; // Set Dirty bit = 1.
                        dirty[{setIndex,1'b1}] = 1'b1;
                        block[{setIndex,1'b1}][cache_width-3:cache_width-7] = address_cache[9:5]; // Update the tag. 
                        tag[{setIndex,1'b1}] = address_cache[9:5];
                        LRU[{setIndex,1'b1}] = 1'b0;

                        if (Byte_offset == 2'b00) begin
                            case (Word_offset)
                                2'b00: block[{setIndex,1'b1}][127:96] = write_data_cache;
                                2'b01: block[{setIndex,1'b1}][95:64] = write_data_cache;
                                2'b10: block[{setIndex,1'b1}][63:32] = write_data_cache;
                                2'b11: block[{setIndex,1'b1}][31:0] = write_data_cache;
                                default: block[{setIndex,1'b1}] = 0;
                            endcase
                        end
                        else begin
                            i = 127 - 32 * Word_offset - 8 * (3-Byte_offset);
                            block[{setIndex,1'b1}][i-:8] = write_data_cache;
                        end                     
                    end
                end
            end

            else begin // read data instruction // lw. 
                if (hit_miss) begin // data is already in cache.
                    if (hit_A) begin
                        if (Byte_offset == 2'b00) begin
                            i = 127 - 32 * Word_offset;
                            read_data_cache = block[{setIndex,1'b0}][i-:32];
                            LRU[setIndex] = 1'b1;
                        end
                        else begin
                            i = 127 - 32 * Word_offset - 8 * (3-Byte_offset);
                            read_data_cache = block[{setIndex,1'b0}][i-:8];
                            LRU[setIndex] = 1'b1;
                        end
                    end
                    else if (hit_B) begin
                        if (Byte_offset == 2'b00) begin
                            i = 127 - 32 * Word_offset;
                            read_data_cache = block[{setIndex,1'b1}][i-:32];
                            LRU[setIndex] = 1'b0;
                        end
                        else begin
                            i = 127 - 32 * Word_offset - 8 * (3-Byte_offset);
                            read_data_cache = block[{setIndex,1'b1}][i-:8];
                            LRU[setIndex] = 1'b0;
                        end
                    end

                end

                else if (!hit_miss) begin // Replace refer to LRU
                    if (LRU[setIndex] == 1'b0) begin // Replace set A.
                        if (Dirty_A) begin // Need to write back to Main Memory first, then change the cache. 
                            read_write_mem = 1'b1; // Write to main memory. 
                            address_mem = {{Tag_A, setIndex}, {4{1'b0}}}; // Start from word0.
                            for (i = 0; i < 4; i = i + 1) begin
                                case (i)
                                    0: write_data_mem = block_A[127:96];
                                    1: write_data_mem = block_A[95:64];
                                    2: write_data_mem = block_A[63:32];
                                    3: write_data_mem = block_A[31:0];
                                    default: write_data_mem = 32'b0;
                                endcase

                                @(posedge done) begin
                                    address_mem = address_mem + 4;
                                end
                            end
                            #1;
                        end

                        // Now read from main memory
                        read_write_mem = 1'b0; // Read from main memory.
                        address_mem = {address_cache[9:4], {4{1'b0}}};

                        for (i = 0; i < 4; i = i + 1) begin
                            @(posedge done) begin
                                case (i)
                                    0: block[{setIndex,1'b0}][127:96] = read_data_mem;
                                    1: block[{setIndex,1'b0}][95:64] = read_data_mem;
                                    2: block[{setIndex,1'b0}][63:32] = read_data_mem;
                                    3: block[{setIndex,1'b0}][31:0] = read_data_mem;
                                    default: block[{setIndex,1'b0}] = 0;
                                endcase
                                address_mem = address_mem + 4;
                            end
                        end
                        
                        block[{setIndex,1'b0}][cache_width-1] = 1'b1; //  Set Valid bit = 1.
                        valid[{setIndex,1'b0}] = 1'b1;
                        block[{setIndex,1'b0}][cache_width-2] = 1'b0; // Set Dirty bit = 0.
                        dirty[{setIndex,1'b0}] = 1'b0;
                        block[{setIndex,1'b0}][cache_width-3:cache_width-7] = address_cache[9:5]; // Update the tag. 
                        tag[{setIndex,1'b0}] = address_cache[9:5];

                        if (Byte_offset == 2'b00) begin
                            i = 127 - 32 * Word_offset;
                            read_data_cache = block[{setIndex,1'b0}][i-:32];
                            LRU[setIndex] = 1'b1;
                        end
                        else begin
                            i = 127 - 32 * Word_offset - 8 * (3-Byte_offset);
                            read_data_cache = block[{setIndex,1'b0}][i-:8];
                            LRU[setIndex] = 1'b1;
                        end
                    end

                    else begin // LRU[setIndex] = 1'b1; Least used block is in set B. 
                            if (Dirty_B) begin // Need to write back to Main Memory first, then change the cache. 
                            read_write_mem = 1'b1; // Write to main memory. 
                            address_mem = {{Tag_B, setIndex}, {4{1'b0}}}; // Start from word0.
                            for (i = 0; i < 4; i = i + 1) begin
                                case (i)
                                    0: write_data_mem = block_B[127:96];
                                    1: write_data_mem = block_B[95:64];
                                    2: write_data_mem = block_B[63:32];
                                    3: write_data_mem = block_B[31:0];
                                    default: write_data_mem = 32'b0;
                                endcase

                                @(posedge done) begin
                                    address_mem = address_mem + 4;
                                end
                            end
                            #1;
                        end

                        // Now read from main memory
                        read_write_mem = 1'b0; // Read from main memory.
                        address_mem = {address_cache[9:4], {4{1'b0}}};

                        for (i = 0; i < 4; i = i + 1) begin
                            @(posedge done) begin
                                case (i)
                                    0: block[{setIndex,1'b1}][127:96] = read_data_mem;
                                    1: block[{setIndex,1'b1}][95:64] = read_data_mem;
                                    2: block[{setIndex,1'b1}][63:32] = read_data_mem;
                                    3: block[{setIndex,1'b1}][31:0] = read_data_mem;
                                    default: block[{setIndex,1'b1}] = 0;
                                endcase
                                address_mem = address_mem + 4;
                            end
                        end
                        
                        block[{setIndex,1'b1}][cache_width-1] = 1'b1; //  Set Valid bit = 1.
                        valid[{setIndex,1'b1}] = 1'b1;
                        block[{setIndex,1'b1}][cache_width-2] = 1'b0; // Set Dirty bit = 0.
                        dirty[{setIndex,1'b1}] = 1'b0;
                        block[{setIndex,1'b1}][cache_width-3:cache_width-7] = address_cache[9:5]; // Update the tag. 
                        tag[{setIndex,1'b1}] = address_cache[9:5];

                        if (Byte_offset == 2'b00) begin
                            i = 127 - 32 * Word_offset;
                            read_data_cache = block[{setIndex,1'b1}][i-:32];
                            LRU[setIndex] = 1'b0;     
                        end
                        else begin
                            i = 127 - 32 * Word_offset - 8 * (3-Byte_offset);
                            read_data_cache = block[{setIndex,1'b1}][i-:8];
                            LRU[setIndex] = 1'b0;    
                        end
                    end
                end
            end
        end
    end


endmodule
