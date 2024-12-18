///////////////////////////////////////////////////////
// debouncer.v
// Function: Performs hardware-based debouncing on input button signal (I)
// Method: Updates output (O) to match input only if there is no change 
//         in the input state for a certain period.
///////////////////////////////////////////////////////
module debouncer(
    input clk,     // System clock (100MHz)
    input I,       // Original button signal with noise
    output reg O   // Debounced output signal
    );
    
    reg [19:0] cnt = 0; // Stabilization counter
    reg Iv = 0;         // Previous stabilized reference signal
    
    always @(posedge clk) begin
        if (I == Iv) begin
            // Increment counter if input state is unchanged
            if (cnt < 20'd999999) begin 
                cnt <= cnt + 1;
            end else begin
                // Update O if no change occurs for a sufficiently long period (~10ms)
                O <= I;
            end
        end else begin
            // Reset counter and update reference signal on input state change
            cnt <= 0;
            Iv <= I;
        end
    end
endmodule