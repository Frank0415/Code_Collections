`timescale 1ns / 1ps

module CacheTest;
    
    reg clock;

    parameter half_period = 5;
    integer t = 0;
    
    top test(clock);

    initial begin
        #0 clock = 0;
    end
    
    always #half_period begin
        clock = ~clock;
        t=t+1;
    end
    
    always @(posedge clock) begin
            $display("===============================================");
            $display("Clock cycle %d", t/2);
            $display("Read data = %H", test.read_data_cache);
            $display("hit_miss = %d", test.hit_miss);
            $display("read_write_cache = %d", test.read_write_cache);
            $display("Request number ", test.CPU_db.request_num);
            $display("===============================================");
    end
    initial
        #260 $stop;

endmodule
