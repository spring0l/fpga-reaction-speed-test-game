///////////////////////////////////////////////////////
// seven_seg_display.v
//
// 기능: 현재 반응 시간(current_time), 최고 기록(best_time), FAIL 상태를
//       7세그먼트 디스플레이에 출력하고, 소수점(dp)을 상황에 따라 제어한다.
//
// 동작 방식:
// - current_time과 best_time을 ms 단위로 받은 뒤 각 자릿수(천/백/십/일)로 분해
// - FAIL 상태 시 current_time 부분에 "FAIL" 표시(F=13(d), A=10(a), I=12(c), L=11(b))
// - no_record(최고기록 미보유) 상태 시 best_time 부분에 "----" 표시('-'=14(e))
// - dp는 current_time의 천의 자리와 best_time의 천의 자리에서 조건부로 켜/끄며
//   이를 통해 x.xxx 형식으로 해석하기 쉽게 한다.
// - 8개의 7세그먼트(AN0~AN7)에 current_time 4자리, best_time 4자리를 순환 표시
//
// 입력:
//  - clk        : 시스템 클럭
//  - fail       : FAIL 상태 플래그
//  - current_time : 현재 반응 시간(ms 단위, 최대 9999)
//  - best_time  : 최고 기록(ms 단위, 16'hFFFF면 기록 없음)
//
// 출력:
//  - an   : 7세그먼트 자리 선택 신호(AN0~AN7)
//  - seg  : 각 자리의 세그먼트 출력 (a~g)
//  - dp   : 소수점 출력
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

    // 소수점 표시를 위한 레지스터
    reg dp_reg;
    assign dp = dp_reg;

    // 클럭 분주용 카운터 (디스플레이 멀티플렉싱용)
    reg [19:0] clkdiv;
    always @(posedge clk) clkdiv <= clkdiv + 1;
    
    // best_time == 16'hFFFF일 경우 기록 없음 상태
    wire no_record = (best_time == 16'hFFFF);
    
    // current_time을 각 자리(천/백/십/일)로 분해
    wire [3:0] cur_thousands = current_time/1000;
    wire [3:0] cur_hundreds  = (current_time%1000)/100;
    wire [3:0] cur_tens      = (current_time%100)/10;
    wire [3:0] cur_ones      = current_time%10;
    
    // best_time을 각 자리로 분해, no_record일 경우 '-'(14) 표시
    wire [3:0] bst_thousands = no_record ? 4'he : best_time/1000; 
    wire [3:0] bst_hundreds  = no_record ? 4'he : (best_time%1000)/100;
    wire [3:0] bst_tens      = no_record ? 4'he : (best_time%100)/10;
    wire [3:0] bst_ones      = no_record ? 4'he : best_time%10;
    
    // FAIL일 경우 current_time 대신 "FAIL" 표시
    // F=13(d), A=10(a), I=12(c), L=11(b)
    reg [3:0] cur_digit[3:0];
    always @(*) begin
        if(fail) begin
            cur_digit[3] = 4'hd; //F
            cur_digit[2] = 4'ha; //A
            cur_digit[1] = 4'hc; //I
            cur_digit[0] = 4'hb; //L
        end else begin
            cur_digit[3] = cur_thousands;
            cur_digit[2] = cur_hundreds;
            cur_digit[1] = cur_tens;
            cur_digit[0] = cur_ones;
        end
    end
    
    // best_time 디지트 그룹
    reg [3:0] bst_digit[3:0];
    always @(*) begin
        bst_digit[3] = bst_thousands;
        bst_digit[2] = bst_hundreds;
        bst_digit[1] = bst_tens;
        bst_digit[0] = bst_ones;
    end
    
    // 현재 선택된 디지트
    reg [3:0] digit;
    wire [6:0] seg_out;

    // 숫자/문자를 7세그먼트로 디코딩
    seg_decoder decoder(.digit(digit), .seg(seg_out));
    
    // 멀티플렉싱: 8개 자릿수를 빠르게 순환하며 각 자리 디스플레이
    // current_time 4자리: AN3~AN0
    // best_time 4자리: AN7~AN4
    always @(*) begin
        case(clkdiv[19:17])
            3'b000: begin an=8'b11111110; digit = cur_digit[0]; end
            3'b001: begin an=8'b11111101; digit = cur_digit[1]; end
            3'b010: begin an=8'b11111011; digit = cur_digit[2]; end
            3'b011: begin an=8'b11110111; digit = cur_digit[3]; end // current_time thousands
            3'b100: begin an=8'b11101111; digit = bst_digit[0]; end
            3'b101: begin an=8'b11011111; digit = bst_digit[1]; end
            3'b110: begin an=8'b10111111; digit = bst_digit[2]; end
            3'b111: begin an=8'b01111111; digit = bst_digit[3]; end // best_time thousands
        endcase
    end

    always @(*) seg = seg_out;

    // dp 제어 로직:
    // - FAIL 상태일 때 current_time 천의 자리 dp 꺼짐
    // - no_record 상태일 때 best_time 천의 자리 dp 꺼짐
    // - 그 외 current_time 천의 자리, best_time 천의 자리 dp 켬
    always @(*) begin
        case(clkdiv[19:17])
            3'b011: begin
                // current_time thousands 자리
                if(fail)
                    dp_reg = 1; // FAIL 시 dp off
                else
                    dp_reg = 0; // FAIL 아님 -> dp on
            end
            3'b111: begin
                // best_time thousands 자리
                if(no_record)
                    dp_reg = 1; // 기록 없으면 dp off
                else
                    dp_reg = 0; // 기록 있으면 dp on
            end
            default:
                dp_reg = 1; // 나머지 자리는 dp off
        endcase
    end
    
endmodule
