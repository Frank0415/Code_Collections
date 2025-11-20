`timescale 1ns / 1ps

// Main memory module simulating a byte-addressable RAM with 1024 bytes
// Handles read and write operations with a done signal to indicate completion
module main_memory(
    input wire read_write_mem,  // 1 for write, 0 for read
    input wire [9:0] address_mem,  // 10-bit address for memory access
    input wire [31:0] write_data_mem,  // 32-bit data to write
    output reg [31:0] read_data_mem,  // 32-bit data read from memory
    output reg Done  // Signal indicating operation completion
);

// Memory storage: 1024 bytes (8-bit each)
reg [7:0] memory_array [1023:0];

integer i;

// Initialize memory and outputs
initial begin
    for (i = 0; i < 1024; i = i + 1) begin
        memory_array[i] = 8'b0;
    end
    Done = 1'b0;
    read_data_mem = 32'b0;
end

// Handle memory operations on changes to read_write_mem or address_mem
always @(read_write_mem or address_mem) begin
    #2 Done = 1'b0;  // Reset done signal at start of operation
    if (read_write_mem == 1'b1) begin  // Write operation: store 32-bit data as 4 bytes
        memory_array[address_mem] = write_data_mem[7:0];      // Byte 0
        memory_array[address_mem + 1] = write_data_mem[15:8];  // Byte 1
        memory_array[address_mem + 2] = write_data_mem[23:16]; // Byte 2
        memory_array[address_mem + 3] = write_data_mem[31:24]; // Byte 3
    end else begin  // Read operation: assemble 32-bit data from 4 bytes
        read_data_mem[7:0] = memory_array[address_mem];       // Byte 0
        read_data_mem[15:8] = memory_array[address_mem + 1];   // Byte 1
        read_data_mem[23:16] = memory_array[address_mem + 2];  // Byte 2
        read_data_mem[31:24] = memory_array[address_mem + 3];  // Byte 3
    end
    #2 Done = 1'b1;  // Set done signal after operation completes
end

endmodule
