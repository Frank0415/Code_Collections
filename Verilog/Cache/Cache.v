`timescale 1ns / 1ps

// Direct-mapped cache module with 4 blocks, each holding 4 words (128 bits data + 6 bits metadata)
// Supports read and write operations, handles cache misses by fetching from main memory
module Cache(
    input wire read_write_cache,  // 1 for write, 0 for read operation
    input wire [9:0] address_cache,  // 10-bit address from CPU
    input wire [31:0] write_data_cache,  // Data to write on write operations
    input wire Done,  // Signal from main memory indicating operation completion
    input wire [31:0] read_data_mem,  // Data read from main memory
    output reg [31:0] read_data_cache,  // Data output to CPU
    output wire hit_miss,  // 1 if cache hit, 0 if miss
    output reg read_write_mem,  // Control signal to main memory (1 write, 0 read)
    output reg [9:0] address_mem,  // Address sent to main memory
    output reg [31:0] write_data_mem  // Data to write to main memory
);

// Cache configuration parameters
parameter num_blocks = 4;  // Total number of cache blocks
parameter tag_width = 4;  // Width of tag bits
parameter block_size = 134;  // Total bits per block: valid(1) + dirty(1) + tag(4) + data(128)

// Extracted fields from cache block
wire is_valid;  // Validity bit of the current block
wire is_dirty;  // Dirty bit indicating if block needs write-back
wire [tag_width-1:0] tag_bits;  // Tag bits for address matching
wire [1:0] block_idx;  // Index to select which block
wire [block_size-1:0] cache_block;  // Current block data
wire tag_match;  // 1 if tag matches address tag
wire [1:0] byte_offset;  // Byte offset within word (not used in this implementation)
wire [1:0] word_offset;  // Word offset within block

// Cache storage: array of blocks
reg [block_size-1:0] cache_blocks [num_blocks-1:0];

integer i;

// Initialize cache and output signals
initial begin
    read_write_mem = 0;
    address_mem = 0;
    write_data_mem = 0;
    for (i = 0; i < num_blocks; i = i + 1) begin
        cache_blocks[i] = 0;
    end
end

// Decode address fields
assign block_idx = address_cache[5:4];  // Bits 5:4 select the block
assign cache_block = cache_blocks[block_idx];  // Get the selected block
assign is_valid = cache_block[block_size-1];  // Valid bit is MSB
assign is_dirty = cache_block[block_size-2];  // Dirty bit is next
assign tag_bits = cache_block[block_size-3 : block_size-6];  // Tag bits
assign tag_match = (tag_bits == address_cache[9:6]);  // Compare with address tag
assign word_offset = address_cache[3:2];  // Bits 3:2 select word within block
assign byte_offset = address_cache[1:0];  // Bits 1:0 are byte offset (unused)

// Hit detection: valid and tag match
assign hit_miss = is_valid & tag_match;

always @(*) begin
    if (read_write_cache) begin  // Write operation
        if (hit_miss) begin  // Cache hit: write directly to cache
            case (word_offset)
                2'b00: cache_blocks[block_idx][31:0] = write_data_cache;
                2'b01: cache_blocks[block_idx][63:32] = write_data_cache;
                2'b10: cache_blocks[block_idx][95:64] = write_data_cache;
                2'b11: cache_blocks[block_idx][127:96] = write_data_cache;
                default: cache_blocks[block_idx] = 0;
            endcase
            cache_blocks[block_idx][block_size-2] = 1'b1;  // Mark block as dirty
        end else begin  // Cache miss: handle replacement
            if (is_dirty) begin  // Write back dirty block to memory
                read_write_mem = 1'b1;  // Set to write mode
                address_mem = {tag_bits, block_idx, 4'b0000};  // Start address for block
                for (i = 0; i < 4; i = i + 1) begin
                    case (i)
                        0: write_data_mem = cache_block[31:0];
                        1: write_data_mem = cache_block[63:32];
                        2: write_data_mem = cache_block[95:64];
                        3: write_data_mem = cache_block[127:96];
                        default: write_data_mem = 32'b0;
                    endcase
                    @(posedge Done) begin
                        address_mem = address_mem + 4;  // Increment address for next word
                    end
                end
                #7;  // Delay for write-back completion
            end

            // Fetch new block from main memory
            read_write_mem = 1'b0;  // Set to read mode
            address_mem = {address_cache[9:4], 4'b0000};  // Start address for new block
            for (i = 0; i < 4; i = i + 1) begin
                @(posedge Done) begin
                    case (i)
                        0: cache_blocks[block_idx][31:0] = read_data_mem;
                        1: cache_blocks[block_idx][63:32] = read_data_mem;
                        2: cache_blocks[block_idx][95:64] = read_data_mem;
                        3: cache_blocks[block_idx][127:96] = read_data_mem;
                        default: cache_blocks[block_idx] = 0;
                    endcase
                    address_mem = address_mem + 4;  // Increment address
                end
            end

            // Update block metadata
            cache_blocks[block_idx][block_size-1] = 1'b1;  // Set valid
            cache_blocks[block_idx][block_size-2] = 1'b1;  // Set dirty (since we'll write)
            cache_blocks[block_idx][block_size-3:block_size-6] = address_cache[9:6];  // Update tag

            // Write the data to the cache
            case (word_offset)
                2'b00: cache_blocks[block_idx][31:0] = write_data_cache;
                2'b01: cache_blocks[block_idx][63:32] = write_data_cache;
                2'b10: cache_blocks[block_idx][95:64] = write_data_cache;
                2'b11: cache_blocks[block_idx][127:96] = write_data_cache;
                default: cache_blocks[block_idx] = 0;
            endcase
        end
    end else begin  // Read operation
        if (hit_miss) begin  // Cache hit: read from cache
            i = 31 + 32 * word_offset;  // Calculate bit position (ignoring byte_offset for word access)
            read_data_cache = cache_blocks[block_idx][i-:32];
        end else begin  // Cache miss: fetch from memory
            if (is_dirty) begin  // Write back if dirty
                read_write_mem = 1'b1;
                address_mem = {tag_bits, block_idx, 4'b0000};
                for (i = 0; i < 4; i = i + 1) begin
                    case (i)
                        0: write_data_mem = cache_block[31:0];
                        1: write_data_mem = cache_block[63:32];
                        2: write_data_mem = cache_block[95:64];
                        3: write_data_mem = cache_block[127:96];
                        default: write_data_mem = 32'b0;
                    endcase
                    @(posedge Done) begin
                        address_mem = address_mem + 4;
                    end
                end
                #1;  // Short delay
            end

            // Fetch new block
            read_write_mem = 1'b0;
            address_mem = {address_cache[9:4], 4'b0000};
            for (i = 0; i < 4; i = i + 1) begin
                @(posedge Done) begin
                    case (i)
                        0: cache_blocks[block_idx][31:0] = read_data_mem;
                        1: cache_blocks[block_idx][63:32] = read_data_mem;
                        2: cache_blocks[block_idx][95:64] = read_data_mem;
                        3: cache_blocks[block_idx][127:96] = read_data_mem;
                        default: cache_blocks[block_idx] = 0;
                    endcase
                    address_mem = address_mem + 4;
                end
            end

            // Update metadata
            cache_blocks[block_idx][block_size-1] = 1'b1;  // Valid
            cache_blocks[block_idx][block_size-2] = 1'b0;  // Clean (just loaded)
            cache_blocks[block_idx][block_size-3:block_size-6] = address_cache[9:6];  // Tag

            // Read the requested data
            i = 31 + 32 * word_offset;
            read_data_cache = cache_blocks[block_idx][i-:32];
        end
    end
end

endmodule
