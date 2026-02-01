`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/04/2025 09:15:43 AM
// Design Name: 
// Module Name: test_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module i2c_txtlcd_top(
    input clk, reset_p,
    input [7:0] send_buffer,
    input send, rs,
    output scl, sda,
    output busy,
    output [15:0]led);

    wire send_pedge;
    edge_detector_p ed_start(.clk(clk), .reset_p(reset_p), .cp(send), .p_edge(send_pedge));
        
    integer cnt_sysclk;
    reg count_clk_e;
    always @(negedge clk, posedge reset_p)begin
        if(reset_p)cnt_sysclk = 0;
        else if(count_clk_e)cnt_sysclk = cnt_sysclk + 1;
        else cnt_sysclk = 0;
    end
    
    reg [7:0] send_buffer_byte;
    i2c_lcd_send_byte send_byte_a(clk, reset_p, 7'h27, send_buffer_byte,     
                                send_byte, rs_byte, scl, sda, busy, led);
      
    localparam IDLE           = 6'b00_0001;
    localparam INIT           = 6'b00_0010;
    localparam SEND_BYTE      = 6'b00_0100;
    
    reg [5:0] state, next_state;
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)state = IDLE;
        else state = next_state;
    end
    
    reg init_flag;
    reg [10:0] cnt_data;
    reg send_byte, rs_byte;

    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            next_state = IDLE;
            init_flag = 0;
            cnt_data = 0;
            count_clk_e = 0;
            send_byte = 0;
            send_buffer_byte = 0;
            rs_byte = 0;
        end
        else begin
            case(state)
                IDLE               :begin
                    if(init_flag)begin
                        if(send_pedge)next_state = SEND_BYTE;
                    end
                    else begin
                        if(cnt_sysclk <= 80_000_00)begin
                            count_clk_e = 1;    
                        end
                        else begin
                            count_clk_e = 0;
                            next_state = INIT;
                        end                     
                    end
                end
                INIT               :begin
                    if(busy)begin
                        send_byte = 0;
                        if(cnt_data >= 6)begin
                            cnt_data = 0;
                            next_state = IDLE;
                            init_flag = 1;
                        end
                    end
                    else if(!send_byte)begin
                        case(cnt_data)
                            0: send_buffer_byte = 8'h33;
                            1: send_buffer_byte = 8'h32;
                            2: send_buffer_byte = 8'h28;
                            3: send_buffer_byte = 8'h0F; // 화면켜짐, 커서있음, 커서깜빡임
                            4: send_buffer_byte = 8'h01; // clear display
                            5: send_buffer_byte = 8'h06; // 커서 오른쪽으로 shift
                        endcase
                        send_byte = 1;
                        cnt_data = cnt_data + 1;
                    end
                end
                SEND_BYTE     :begin
                    if(busy)begin
                        send_byte = 0;
                        next_state = IDLE;
                    end
                    else if(!send_byte) begin
                        rs_byte = rs; // 0이면 명령어, 1이면 데이터 
                        send_buffer_byte = send_buffer;
                        send_byte = 1;
                    end                
                end
            endcase
        end
    end   
endmodule









