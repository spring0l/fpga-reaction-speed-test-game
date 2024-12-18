///////////////////////////////////////////////////////
// seg_decoder.v
//
// Function: Decodes a 4-bit input (digit) into the corresponding 
//           7-segment display pattern.
//
// Mapping:
// 0~9 : Numeric display
// A, L, I, F, '-' : Character display
// Outputs the decoded result to seg (a~g segment activation)
//
// Input:
// - digit : Value to display (0~9, A=10, L=11, I=12, F=13, '-'=14)
//
// Output:
// - seg : 7-segment pattern corresponding to the digit (active low)
//
// Note:
// 'I' resembles 1, and 'L' is represented with a simple pattern.
///////////////////////////////////////////////////////
module seg_decoder(
    input [3:0] digit,
    output reg [6:0] seg
    );
    always @(*) begin
        case(digit)
            4'd0: seg = 7'b1000000; // 0
            4'd1: seg = 7'b1111001; // 1
            4'd2: seg = 7'b0100100; // 2
            4'd3: seg = 7'b0110000; // 3
            4'd4: seg = 7'b0011001; // 4
            4'd5: seg = 7'b0010010; // 5
            4'd6: seg = 7'b0000010; // 6
            4'd7: seg = 7'b1111000; // 7
            4'd8: seg = 7'b0000000; // 8
            4'd9: seg = 7'b0010000; // 9
            4'ha: seg = 7'b0001000; // A
            4'hb: seg = 7'b1000111; // L
            4'hc: seg = 7'b1111001; // I (resembles 1)
            4'hd: seg = 7'b0001110; // F
            4'he: seg = 7'b0111111; // '-'
            default: seg = 7'b1111111; // Default: all segments off
        endcase
    end
endmodule