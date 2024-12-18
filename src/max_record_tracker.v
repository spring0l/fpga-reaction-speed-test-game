///////////////////////////////////////////////////////
// max_record_tracker.v
// Function: Manages the best record
// Operation:
// - Initializes best_time to a very large value (FFFFh) when rst signal is asserted
// - On update signal, compares current_time with best_time, and updates best_time 
//   if current_time is smaller
///////////////////////////////////////////////////////
module max_record_tracker(
    input clk,
    input rst,
    input update,
    input [15:0] current_time,
    output reg [15:0] best_time
    );
    
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            best_time <= 16'hFFFF; // Initialize to no record state
        end else if(update) begin
            if(current_time < best_time)
                best_time <= current_time; // Update with a faster record
        end
    end
endmodule