///////////////////////////////////////////////////////
// seven_seg_display.v
//
// Function: Displays the current reaction time (current_time), 
//           the best record (best_time), and FAIL status on a 7-segment display.
//           Controls the decimal point (dp) based on conditions.
//
// Operation:
// - Decomposes current_time and best_time (in ms) into digits (thousands/hundreds/tens/ones).
// - Displays "FAIL" on current_time when in FAIL state (F=13(d), A=10(a), I=12(c), L=11(b)).
// - Displays "----" on best_time when no record is available ('-'=14(e)).
// - Turns on dp for thousands place of current_time and best_time to display x.xxx format.
// - Multiplexes 8 segments (AN0~AN7) to sequentially display current_time and best_time.
//
// Input:
// - clk         : System clock
// - fail        : FAIL state flag
// - current_time: Current reaction time (in ms, max 9999)
// - best_time   : Best record (in ms, 16'hFFFF means no record)
//
// Output:
// - an   : Digit selection signals for 7-segment display (AN0~AN7)
// - seg  : Segment outputs for each digit (a~g)
// - dp   : Decimal point output
///////////////////////////////////////////////////////

module seven_seg_display(
    input clk,
    input fail,
    input [15:0] current_time,
    input [15:0] best_time,
    output reg [7:0] an,
    output reg [6:0] seg,
    output dp
    );

    // Register for controlling the decimal point
    reg dp_reg;
    assign dp = dp_reg;

    // Clock divider counter for multiplexing display
    reg [19:0] clkdiv;
    always @(posedge clk) clkdiv <= clkdiv + 1;
    
    // No record flag: true if best_time == 16'hFFFF
    wire no_record = (best_time == 16'hFFFF);
    
    // Decompose current_time into digits (thousands/hundreds/tens/ones)
    wire [3:0] cur_thousands = current_time / 1000;
    wire [3:0] cur_hundreds  = (current_time % 1000) / 100;
    wire [3:0] cur_tens      = (current_time % 100) / 10;
    wire [3:0] cur_ones      = current_time % 10;
    
    // Decompose best_time into digits, or display '-' (14) if no record
    wire [3:0] bst_thousands = no_record ? 4'he : best_time / 1000; 
    wire [3:0] bst_hundreds  = no_record ? 4'he : (best_time % 1000) / 100;
    wire [3:0] bst_tens      = no_record ? 4'he : (best_time % 100) / 10;
    wire [3:0] bst_ones      = no_record ? 4'he : best_time % 10;
    
    // If FAIL, replace current_time with "FAIL" (F=13, A=10, I=12, L=11)
    reg [3:0] cur_digit[3:0];
    always @(*) begin
        if(fail) begin
            cur_digit[3] = 4'hd; // F
            cur_digit[2] = 4'ha; // A
            cur_digit[1] = 4'hc; // I
            cur_digit[0] = 4'hb; // L
        end else begin
            cur_digit[3] = cur_thousands;
            cur_digit[2] = cur_hundreds;
            cur_digit[1] = cur_tens;
            cur_digit[0] = cur_ones;
        end
    end
    
    // Group best_time digits
    reg [3:0] bst_digit[3:0];
    always @(*) begin
        bst_digit[3] = bst_thousands;
        bst_digit[2] = bst_hundreds;
        bst_digit[1] = bst_tens;
        bst_digit[0] = bst_ones;
    end
    
    // Selected digit and decoded output
    reg [3:0] digit;
    wire [6:0] seg_out;

    // Decode digit to 7-segment pattern
    seg_decoder decoder(.digit(digit), .seg(seg_out));
    
    // Multiplexing: cycle through 8 digits
    // current_time: AN3~AN0, best_time: AN7~AN4
    always @(*) begin
        case(clkdiv[19:17])
            3'b000: begin an = 8'b11111110; digit = cur_digit[0]; end
            3'b001: begin an = 8'b11111101; digit = cur_digit[1]; end
            3'b010: begin an = 8'b11111011; digit = cur_digit[2]; end
            3'b011: begin an = 8'b11110111; digit = cur_digit[3]; end // current_time thousands
            3'b100: begin an = 8'b11101111; digit = bst_digit[0]; end
            3'b101: begin an = 8'b11011111; digit = bst_digit[1]; end
            3'b110: begin an = 8'b10111111; digit = bst_digit[2]; end
            3'b111: begin an = 8'b01111111; digit = bst_digit[3]; end // best_time thousands
        endcase
    end

    always @(*) seg = seg_out;

    // Control dp logic:
    // - Turn off dp in current_time thousands place if in FAIL state.
    // - Turn off dp in best_time thousands place if no record exists.
    // - Otherwise, turn on dp for thousands places.
    always @(*) begin
        case(clkdiv[19:17])
            3'b011: begin
                // current_time thousands place
                if(fail)
                    dp_reg = 1; // Turn off dp in FAIL state
                else
                    dp_reg = 0; // Turn on dp
            end
            3'b111: begin
                // best_time thousands place
                if(no_record)
                    dp_reg = 1; // Turn off dp if no record
                else
                    dp_reg = 0; // Turn on dp
            end
            default:
                dp_reg = 1; // Turn off dp for other places
        endcase
    end
    
endmodule