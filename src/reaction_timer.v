///////////////////////////////////////////////////////
// reaction_timer.v
// Function: Measures the time (in ms) from when the LED turns on 
//           until the user presses the reaction button.
// Operation:
// - When the start signal is asserted, set time_ms=0 and running=1 to start counting.
// - When the stop signal is asserted, set running=0 to stop counting.
// - While in the running state, increment time_ms on each tick_1ms pulse.
///////////////////////////////////////////////////////
module reaction_timer(
    input clk,         // 100MHz clock
    input tick_1ms,    // 1ms pulse
    input start,       // Timer start trigger
    input stop,        // Timer stop trigger
    input reset,       // Timer reset
    output reg [15:0] time_ms
    );

    reg running = 0; // Running state flag
    
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            time_ms <= 0;       // Reset time counter
            running <= 0;       // Stop timer
        end else begin
            if(start) begin
                running <= 1;   // Start timer
                time_ms <= 0;   // Reset counter to 0
            end else if(stop) begin
                running <= 0;   // Stop timer
            end else if(running && tick_1ms) begin
                time_ms <= time_ms + 1; // Increment time in ms
            end
        end
    end
endmodule