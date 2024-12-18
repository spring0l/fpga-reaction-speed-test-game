///////////////////////////////////////////////////////
// reaction_timer.v
// 기능: LED가 켜진 순간부터 사용자가 반응 버튼을 누를 때까지의 시간(ms)을 계측
// 동작:
// - start 신호 발생 시 time_ms=0, running=1 시작
// - stop 신호 발생 시 running=0 정지
// - running 상태일 때 tick_1ms 입력 시 time_ms 증가
///////////////////////////////////////////////////////
module reaction_timer(
    input clk,         // 100MHz 클럭
    input tick_1ms,    // 1ms 펄스
    input start,       // 타이머 시작 트리거
    input stop,        // 타이머 정지 트리거
    input reset,       // 타이머 리셋
    output reg [15:0] time_ms
    );

    reg running = 0;
    
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            time_ms <= 0;
            running <= 0;
        end else begin
            if(start) begin
                running <= 1;
                time_ms <= 0;
            end else if(stop) begin
                running <= 0;
            end else if(running && tick_1ms) begin
                time_ms <= time_ms + 1;
            end
        end
    end
endmodule
