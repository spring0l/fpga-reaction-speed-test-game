///////////////////////////////////////////////////////
// lfsr_random.v
// Function: Generates random numbers using a Linear Feedback Shift Register (LFSR)
//           Maps the generated random number to a specific range (500~3500ms)
///////////////////////////////////////////////////////

module lfsr_random(
    input clk,          // System clock
    input reset,        // Global reset signal (used for game reset)
    output reg [11:0] random_value // Generated random value (500 ~ 3500ms)
    );
    // LFSR initialization and implementation
    reg [11:0] lfsr_reg = 12'hACE; // Initial LFSR value
    wire feedback = lfsr_reg[11] ^ lfsr_reg[3] ^ lfsr_reg[2] ^ lfsr_reg[0]; 
    
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            // On reset, initialize LFSR to the initial value
            lfsr_reg <= 12'hACE;
        end else begin
            // Shift LFSR with feedback
            lfsr_reg <= {lfsr_reg[10:0], feedback};
        end
    end
    
    always @(*) begin
        // Map 0~4095 range random value to 500~3500ms
        random_value = (lfsr_reg % 3001) + 500; 
    end
endmodule
