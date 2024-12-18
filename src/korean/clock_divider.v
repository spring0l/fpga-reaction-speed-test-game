///////////////////////////////////////////////////////
// clock_divider.v
// 기능: 100MHz 입력 클럭으로부터 1ms 주기의 tick 신호 생성
// 100MHz -> 주기 10ns, 1ms = 100,000 cycles
// count==99999에 도달할 때 tick_1ms를 1로 출력
///////////////////////////////////////////////////////
module clock_divider(
    input clk,         // 100MHz 입력 클럭
    output reg tick_1ms // 1ms마다 1 사이클 동안 1을 출력하는 펄스
    );
    
    reg [16:0] count = 0;
    always @(posedge clk) begin
        if (count == 17'd99999) begin
            count <= 0;
            tick_1ms <= 1;
        end else begin
            count <= count + 1;
            tick_1ms <= 0;
        end
    end
endmodule
