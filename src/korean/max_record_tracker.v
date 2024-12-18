///////////////////////////////////////////////////////
// max_record_tracker.v
// 기능: 최고 기록 관리
// 동작:
// - rst 신호 시 best_time을 매우 큰 값(FFFFh)으로 초기화
// - update 신호 발생 시 current_time과 비교, 더 작으면 best_time 갱신
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
            best_time <= 16'hFFFF; // 기록 없음 상태
        end else if(update) begin
            if(current_time < best_time)
                best_time <= current_time; // 더 빠른 기록 갱신
        end
    end
endmodule
