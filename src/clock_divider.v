///////////////////////////////////////////////////////
// clock_divider.v
// Function: Generates a 1ms tick signal from a 100MHz input clock
// 100MHz -> Period = 10ns, 1ms = 100,000 cycles
// Outputs tick_1ms as 1 when count reaches 99999
///////////////////////////////////////////////////////
module clock_divider(
    input clk,         // 100MHz input clock
    output reg tick_1ms // Pulse output: 1 for 1 cycle every 1ms
    );
    
    reg [16:0] count = 0; // Counter for 100,000 cycles
    always @(posedge clk) begin
        if (count == 17'd99999) begin
            count <= 0;       // Reset counter
            tick_1ms <= 1;    // Generate 1-cycle pulse
        end else begin
            count <= count + 1; // Increment counter
            tick_1ms <= 0;      // Keep pulse low otherwise
        end
    end
endmodule