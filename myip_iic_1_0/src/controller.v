`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/08/2025 03:32:10 PM
// Design Name: 
// Module Name: controller
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


module FND_cntr(
    input clk, reset_p,
    input [15:0] fnd_value,
    output [7:0] seg,
    output reg [3:0] com);
    
    reg [16:0] clk_div;
    always @(posedge clk)clk_div = clk_div + 1;
    
    wire clk_div_ed;
    edge_detector_n ed_com(.clk(clk), .reset_p(reset_p),
                    .cp(clk_div[16]), .p_edge(clk_div_ed));
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)com = 4'b1110;
        else if(clk_div_ed)begin
            if(com[0] + com[1] + com[2] + com[3] != 3) com = 4'b1110;
            else com = {com[2:0], com[3]};
        end
    end
    reg [3:0] digit_value;
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)digit_value = 0;
        else begin
            case(com)
                4'b1110: digit_value = fnd_value[3:0];
                4'b1101: digit_value = fnd_value[7:4];
                4'b1011: digit_value = fnd_value[11:8];
                4'b0111: digit_value = fnd_value[15:12];
            endcase
        end
    end
    seg_decoder dec(.hex_value(digit_value), .seg(seg));
    
endmodule

module button_cntr(
    input clk, reset_p, btn,
    output btn_pedge, btn_nedge);
    
    reg [15:0] cnt_sysclk;
    reg debounced_btn;
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            cnt_sysclk = 0;
            debounced_btn = 0;
        end
        else begin
            if(cnt_sysclk[15])begin
                debounced_btn = btn;
                cnt_sysclk = 0;
            end
            else cnt_sysclk = cnt_sysclk + 1;
        end
    end
    
    edge_detector_n ed(.clk(clk), .reset_p(reset_p),
                       .cp(debounced_btn), .p_edge(btn_pedge), .n_edge(btn_nedge));
endmodule

module freq_generator(
    input clk, reset_p,
    output reg trans_cp);
    
    
    parameter FREQ = 1_000_000;
    parameter SYS_FREQ = 100_000_000;
    parameter HALF_PERIOD = SYS_FREQ / FREQ / 2 - 1;
    integer cnt;
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            cnt = 0;
            trans_cp = 0;
        end
        else begin
            if(cnt >= HALF_PERIOD)begin
                cnt = 0;
                trans_cp = ~trans_cp;
            end
            else cnt = cnt + 1;
        end
    end

endmodule

module pwm_Nfreq_Nstep(
    input clk, reset_p,
    input [31:0] duty,
    output reg pwm);

    parameter SYS_CLK_FREQ = 100_000_000;
    parameter PWM_FREQ = 10_000;
    parameter DUTY_STEP = 200;
    parameter temp = SYS_CLK_FREQ / (PWM_FREQ * DUTY_STEP) / 2 - 1;
    
    integer cnt;
    reg pwm_freqXstep;
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            cnt = 0;
            pwm_freqXstep = 0;
        end
        else begin
            if(cnt >= temp)begin
                cnt = 0;
                pwm_freqXstep = ~pwm_freqXstep;
            end
            else cnt = cnt + 1;
        end
    end
    wire pwm_freqXstep_pedge;
    edge_detector_n ed(.clk(clk), .reset_p(reset_p),
                       .cp(pwm_freqXstep), .p_edge(pwm_freqXstep_pedge));
                       
    integer cnt_duty;
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            cnt_duty = 0;
            pwm = 0;
        end
        else if(pwm_freqXstep_pedge)begin
            if(cnt_duty >= DUTY_STEP-1)cnt_duty = 0;
            else cnt_duty = cnt_duty + 1;
            
            if(cnt_duty < duty)pwm = 1;
            else pwm = 0;
        end
    end
endmodule

module hc_sr04_cntr(
    input clk, reset_p,
    input echo,
    output reg trig,
    output reg [8:0] distance_cm);
    
    localparam time_1cm = 58;

    integer cnt_sysclk, cnt_sysclk0, cnt_usec;
    reg count_usec_e; 
    reg [8:0] cnt_cm; 
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            cnt_sysclk0 = 0;
            cnt_usec = 0;
            cnt_cm = 0;
        end
        else if(count_usec_e)begin
            if(cnt_sysclk0 >= 99)begin
                cnt_sysclk0 = 0;
                if(cnt_usec >= time_1cm - 1)begin
                    cnt_usec = 0;
                    cnt_cm = cnt_cm + 1;
                end
                else cnt_usec = cnt_usec + 1;
            end
            else cnt_sysclk0 = cnt_sysclk0 + 1;
        end
        else begin
            cnt_sysclk0 = 0;
            cnt_usec = 0;
            cnt_cm = 0;
        end
    end
    
    always @(posedge clk)cnt_sysclk = cnt_sysclk + 1;
    wire cnt26_pedge, cnt9_pedge;
    edge_detector_n ed26(.clk(clk), .reset_p(reset_p),
                       .cp(cnt_sysclk[24]), .p_edge(cnt26_pedge));
    edge_detector_n ed9(.clk(clk), .reset_p(reset_p),
                       .cp(cnt_sysclk[9]), .p_edge(cnt9_pedge));
                       
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)trig = 0;
        else if(cnt26_pedge)trig = 1;
        else if(cnt9_pedge)trig = 0;
    end
    
    wire echo_pedge, echo_nedge;
    edge_detector_n ed_echo(.clk(clk), .reset_p(reset_p),
                       .cp(echo), .p_edge(echo_pedge), .n_edge(echo_nedge));
                     
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            distance_cm = 0;
            count_usec_e = 0;
        end
        else if(echo_pedge)begin
            count_usec_e = 1;
        end
        else if(echo_nedge)begin
            distance_cm = cnt_cm;
            count_usec_e = 0;
        end
    end
endmodule

module dht11_cntr(
    input clk, reset_p,
    inout dht11_data,
    output reg [7:0] humidity, temperature,
    output [15:0] led);

    localparam S_IDLE       = 6'b00_0001;
    localparam S_LOW_18MS   = 6'b00_0010;
    localparam S_HIGH_20US  = 6'b00_0100;
    localparam S_LOW_80US   = 6'b00_1000;
    localparam S_HIGH_80US  = 6'b01_0000;
    localparam S_READ_DATA  = 6'b10_0000;
    
    localparam S_WAIT_PEDGE = 2'b01;
    localparam S_WAIT_NEDGE = 2'b10;
    
    wire clk_usec_nedge;
    clock_usec usec_clk(.clk(clk), .reset_p(reset_p), 
                        .clk_usec_nedge(clk_usec_nedge));
    
    reg [21:0] count_usec;
    reg count_usec_e;
    always @(negedge clk, posedge reset_p)begin
        if(reset_p)count_usec = 0;
        else if(clk_usec_nedge && count_usec_e)count_usec = count_usec + 1;
        else if(!count_usec_e)count_usec = 0;
    end
    
    wire dht_nedge, dht_pedge;
    edge_detector_p ed(.clk(clk), .reset_p(reset_p),
                       .cp(dht11_data), .p_edge(dht_pedge),
                       .n_edge(dht_nedge));
    reg dht11_data_buffer, dht11_data_out_e;
    assign dht11_data = dht11_data_out_e ? dht11_data_buffer : 'bz;  
    
    reg [5:0] state, next_state;
    always @(negedge clk, posedge reset_p)begin
        if(reset_p)state = S_IDLE;
        else state = next_state;
    end  
    assign led[5:0] = state;
    reg [39:0] temp_data;
    reg [5:0] cnt_data;
    assign led[15:10] = cnt_data;
    reg [1:0] read_state;
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            next_state = S_IDLE;
            temp_data = 0;
            cnt_data = 0;
            count_usec_e = 0;
            dht11_data_out_e = 0;
            dht11_data_buffer = 0;
            read_state = S_WAIT_PEDGE;
        end
        else begin
            case(state)
                S_IDLE:begin
                    if(count_usec < 22'd3_000_000)begin
                        count_usec_e = 1;
                        dht11_data_out_e = 0;
                    end
                    else begin
                        count_usec_e = 0;
                        next_state = S_LOW_18MS;
                    end
                end
                S_LOW_18MS:begin
                    if(count_usec < 22'd20_000)begin
                        count_usec_e = 1;
                        dht11_data_out_e = 1;
                        dht11_data_buffer = 0;
                    end
                    else begin
                        count_usec_e = 0;
                        dht11_data_out_e = 0;
                        next_state = S_HIGH_20US;
                    end
                end 
                S_HIGH_20US:begin
                    if(dht_nedge)begin
                        count_usec_e = 0;
                        next_state = S_LOW_80US;
                    end
                end
                S_LOW_80US:begin
                    if(dht_pedge)begin
                        next_state = S_HIGH_80US;
                    end
                end
                S_HIGH_80US:begin
                    if(dht_nedge)begin
                        next_state = S_READ_DATA;
                    end
                end
                S_READ_DATA:begin
                    case(read_state)
                        S_WAIT_PEDGE:begin
                            if(dht_pedge)read_state = S_WAIT_NEDGE;
                            count_usec_e = 0;
                        end
                        S_WAIT_NEDGE:begin
                            count_usec_e = 1;
                            if(dht_nedge)begin
                                if(count_usec < 50) temp_data = {temp_data[38:0], 1'b0};
                                else temp_data = {temp_data[38:0], 1'b1};
                                cnt_data = cnt_data + 1;
                                read_state = S_WAIT_PEDGE;
                            end
                        end
                        default: read_state = S_WAIT_PEDGE;
                    endcase
                    if(cnt_data >= 40)begin
                        next_state = S_IDLE;
                        cnt_data = 0;
                        
                        humidity = temp_data[39:32];
                        temperature = temp_data[23:16];        
                    end
                end
                default: next_state = S_IDLE;
            endcase
        end
    end              
    
endmodule

//module I2C_master(
//    input clk, reset_p,
//    input [6:0] addr,
//    input [7:0] data,
//    input rd_wr, comm_start,
//    output reg scl, sda,
//    output reg busy,
//    output [15:0] led);

//    localparam IDLE         = 7'b000_0001;
//    localparam COMM_START   = 7'b000_0010;
//    localparam SEND_ADDR    = 7'b000_0100;
//    localparam RD_ACK       = 7'b000_1000;
//    localparam SEND_DATA    = 7'b001_0000;
//    localparam SCL_STOP     = 7'b010_0000;
//    localparam COMM_STOP    = 7'b100_0000;

//    wire clk_usec_nedge;
//    clock_usec usec_clk(.clk(clk), .reset_p(reset_p), 
//                        .clk_usec_nedge(clk_usec_nedge));

//    wire comm_start_pedge;
//    edge_detector_p ed_start(.clk(clk), .reset_p(reset_p),
//                       .cp(comm_start), .p_edge(comm_start_pedge));
                       
//    wire scl_pedge, scl_nedge;
//    edge_detector_p ed_scl(.clk(clk), .reset_p(reset_p),
//                       .cp(scl), .p_edge(scl_pedge),
//                       .n_edge(scl_nedge));
    
//    reg [2:0] count_usec5;
//    reg scl_e;
//    always @(posedge clk, posedge reset_p)begin
//        if(reset_p)begin
//            count_usec5 = 0;
//            scl = 1;
//        end
//        else if(scl_e)begin
//            if(clk_usec_nedge)begin
//                if(count_usec5 >= 4)begin
//                    count_usec5 = 0;
//                    scl = ~scl;
//                end
//                else count_usec5 = count_usec5 + 1;
//            end
//        end
//        else if(!scl_e)begin
//            count_usec5 = 0;
//            scl = 1;
//        end
//    end
    
//    reg [6:0] state, next_state;
//    always @(negedge clk, posedge reset_p)begin
//        if(reset_p)state = IDLE;
//        else state = next_state;
//    end

//    wire [7:0] addr_rw;
//    assign addr_rw = {addr, rd_wr};
//    reg [2:0] cnt_bit;
//    reg stop_flag;
//    always @(posedge clk, posedge reset_p)begin
//        if(reset_p)begin
//            next_state = IDLE;
//            scl_e = 0;
//            sda = 0;
//            cnt_bit = 7;
//            stop_flag = 0;
//            busy = 0;
//        end
//        else begin
//            case(state)
//                IDLE      :begin
//                    busy = 0;
//                    scl_e = 0;
//                    sda = 1;
//                    if(comm_start_pedge)next_state = COMM_START;
//                end
//                COMM_START:begin
//                    busy = 1;
//                    sda = 0;
//                    next_state = SEND_ADDR;
//                end
//                SEND_ADDR :begin
//                    scl_e = 1;
//                    if(scl_nedge)sda = addr_rw[cnt_bit];
//                    if(scl_pedge)begin
//                        if(cnt_bit == 0)begin
//                            cnt_bit =7;
//                            next_state = RD_ACK;
//                        end
//                        else cnt_bit = cnt_bit - 1;
//                    end
//                end
//                RD_ACK    :begin
//                    if(scl_nedge)sda = 'bz;
//                    if(scl_pedge)begin
//                        if(stop_flag)begin
//                            stop_flag = 0;
//                            next_state = SCL_STOP;
//                        end
//                        else begin
//                            stop_flag = 1;
//                            next_state = SEND_DATA;
//                        end
//                    end
//                end
//                SEND_DATA :begin
//                    if(scl_nedge)sda = data[cnt_bit];
//                    if(scl_pedge)begin
//                        if(cnt_bit == 0)begin
//                            cnt_bit =7;
//                            next_state = RD_ACK;
//                        end
//                        else cnt_bit = cnt_bit - 1;
//                    end
//                end
//                SCL_STOP  :begin
//                    if(scl_nedge)sda = 0;
//                    if(scl_pedge)next_state = COMM_STOP;
//                end
//                COMM_STOP :begin
//                    if(count_usec5 >= 3)begin
//                        scl_e = 0;
//                        sda = 1;
//                        next_state = IDLE;
//                    end
//                end
//                default   :next_state = IDLE;
//            endcase
//        end
//    end
//endmodule

//module i2c_lcd_send_byte(
//    input clk, reset_p,
//    input [6:0] addr, 
//    input [7:0] send_buffer,
//    input send, rs,
//    output scl, sda,
//    output reg busy,
//    output[15:0] led);

//    localparam IDLE                     = 6'b00_0001;
//    localparam SEND_HIGH_NIBBLE_DISABLE = 6'b00_0010;
//    localparam SEND_HIGH_NIBBLE_ENABLE  = 6'b00_0100;
//    localparam SEND_LOW_NIBBLE_DISABLE  = 6'b00_1000;
//    localparam SEND_LOW_NIBBLE_ENABLE   = 6'b01_0000;
//    localparam SEND_DISABLE             = 6'b10_0000;
    
//    wire clk_usec_nedge;
//    clock_usec usec_clk(.clk(clk), .reset_p(reset_p), 
//                        .clk_usec_nedge(clk_usec_nedge));
//    wire send_pedge;
//    edge_detector_p ed_start(.clk(clk), .reset_p(reset_p),
//                       .cp(send), .p_edge(send_pedge));
                       
//    reg [21:0] count_usec;
//    reg count_usec_e;
//    always @(negedge clk, posedge reset_p)begin
//        if(reset_p)count_usec = 0;
//        else if(clk_usec_nedge && count_usec_e)count_usec = count_usec + 1;
//        else if(!count_usec_e)count_usec = 0;
//    end 
                     
//    reg [7:0] data;
//    reg comm_start;
//    wire i2c_busy;
//    I2C_master master(clk, reset_p, addr, data, 1'b0, 
//                                comm_start, scl, sda, i2c_busy, led);                   
    
//    reg [5:0] state, next_state;
//    always @(negedge clk, posedge reset_p)begin
//        if(reset_p)state = IDLE;
//        else state = next_state;
//    end
    
//    always @(posedge clk, posedge reset_p)begin
//        if(reset_p)begin
//            next_state = IDLE;
//            comm_start = 0;
//            count_usec_e = 0;
//            data = 0;
//            busy = 0;
//        end
//        else begin
//            case(state)
//                IDLE                    :begin
//                    busy = 0;
//                    if(send_pedge)begin
//                        busy = 1;
//                        next_state = SEND_HIGH_NIBBLE_DISABLE;
//                    end
//                end
//                SEND_HIGH_NIBBLE_DISABLE:begin
//                    if(count_usec >= 22'd200)begin
//                        comm_start = 0;
//                        next_state =  SEND_HIGH_NIBBLE_ENABLE;
//                        count_usec_e = 0;
//                    end
//                    else begin
//                              //d7 d6 d5 d4  BL en, rw, rs    
//                        data = {send_buffer[7:4], 3'b100, rs};
//                        comm_start = 1;
//                        count_usec_e = 1;
//                    end
//                end
//                SEND_HIGH_NIBBLE_ENABLE :begin
//                    if(count_usec >= 22'd200)begin
//                        comm_start = 0;
//                        next_state = SEND_LOW_NIBBLE_DISABLE;
//                        count_usec_e = 0;
//                    end
//                    else begin
//                        data = {send_buffer[7:4], 3'b110, rs};
//                        comm_start = 1;
//                        count_usec_e = 1;
//                    end
//                end
//                SEND_LOW_NIBBLE_DISABLE :begin
//                    if(count_usec >= 22'd200)begin
//                        comm_start = 0;
//                        next_state =  SEND_LOW_NIBBLE_ENABLE;
//                        count_usec_e = 0;
//                    end
//                    else begin
//                        data = {send_buffer[3:0], 3'b100, rs};
//                        comm_start = 1;
//                        count_usec_e = 1;
//                    end
//                end
//                SEND_LOW_NIBBLE_ENABLE  :begin
//                    if(count_usec >= 22'd200)begin
//                        comm_start = 0;
//                        next_state = SEND_DISABLE;
//                        count_usec_e = 0;
//                    end
//                    else begin
//                        data = {send_buffer[3:0], 3'b110, rs};
//                        comm_start = 1;
//                        count_usec_e = 1;
//                    end
//                end
//                SEND_DISABLE            :begin
//                    if(count_usec >= 22'd200)begin
//                        comm_start = 0;
//                        next_state = IDLE;
//                        count_usec_e = 0;
//                    end
//                    else begin
//                        data = {send_buffer[3:0], 3'b100, rs};
//                        comm_start = 1;
//                        count_usec_e = 1;
//                    end
//                end
//                default: next_state = IDLE;
//            endcase
//        end
//    end
                       
//endmodule

module I2C_master(
    input clk, reset_p,
    input [6:0] addr,
    input [7:0] data,
    input rd_wr, comm_start,
    output reg scl, sda,
    output reg busy,
    output [15:0] led);

    
    //4가지 상태
    localparam IDLE         = 7'b000_0001;
    localparam COMM_STAR    = 7'b000_0010;
    localparam SEND_ADDR    = 7'b000_0100;
    localparam RD_ACK       = 7'b000_1000;
    localparam SEND_DATA    = 7'b001_0000;
    localparam SCL_STOP     = 7'b010_0000;
    localparam COMM_STOP    = 7'b100_0000;

    //아이들 상태 전부다 HIGH 유지해야함
    //SDA, SCL둘다
    //SEND_ADDR 데이터 주소 7비트 
    //COMM_STAR , SDA = LOW로 드다음 데이터 8개 

    //RD_ACK 슬레이브가 엑을 보내옴 하이가 디폴트 그래서 로우가 오면 읽음
    //SEND_DATA 데이터 8개 보내는 상태 
    //RD_ACK 한번더 하고 크락을  멈춤 
    //클락 멈춤 상태에서 하이 를 한번 줘야함 
    //스탑 비트 
    
    
    //us 사용 
    wire clk_usec_nedge;    //1us falling
    clock_usec usec_clk(
                    .clk(clk), 
                    .reset_p(reset_p),
                    .clk_usec_nedge(clk_usec_nedge));

    
    wire comm_start_pedge;
    edge_detector_p ed_start(
                    .clk(clk), 
                    .reset_p(reset_p),
                    .cp(comm_start),
                    .p_edge(comm_start_pedge));
                    
    
    wire scl_nedge, scl_pedge;
    edge_detector_p ed_scl(
                    .clk(clk), 
                    .reset_p(reset_p),
                    .cp(scl),
                    .p_edge(scl_pedge), 
                    .n_edge(scl_nedge));
    
    //1us 클락 0.5us 마다 반전 
    reg [2:0] count_usec5;
    reg scl_e;
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            count_usec5 = 0;
            scl = 1;
        end
        else if(scl_e)begin
            if(clk_usec_nedge)begin //1us
                if(count_usec5 >= 4)begin //2us
                    count_usec5 = 0;
                    scl = ~scl;
                end
                else count_usec5 = count_usec5 + 1;
            end
        end
        else if(!scl_e)begin
            count_usec5 = 0;
            scl = 1;
        end
    end
    
    reg [6:0] state, next_state;
    always @(negedge clk, posedge reset_p)begin
        if(reset_p)state = IDLE;
        else state =  next_state;
    
    end
    
    wire [7:0] addr_rw; //주소 읽기 쓰기 기능 1 : 읽기 모드 , 0 : 쓰기 모드   
    assign addr_rw = {addr, rd_wr};
    reg [2:0] cnt_bit;
    //flag 추가
    reg stop_flag;
    
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            next_state = IDLE;
            scl_e = 0;
            sda = 0;
            cnt_bit = 7;
            //상위 비트 부터 보내기 때문에 
            stop_flag = 0;
            busy = 0;
        end
        else begin
            case(state)
            
                 IDLE     :begin
                    busy = 0;
                    scl_e = 0; //멈춰있음
                    sda = 1;
                    if(comm_start_pedge)next_state = COMM_STAR;
                 end 
                 COMM_STAR:begin
                    busy = 1;
                    sda = 0; //폴링 엣지 발생 
                    next_state = SEND_ADDR;
                 end
                 SEND_ADDR:begin    //클락이 하락떠렁지면 최상위비트 부터 SDA의 출력 
                    scl_e = 1;  //클락 발생 
                    if(scl_nedge)sda = addr_rw[cnt_bit];
                    if(scl_pedge)begin
                        if(cnt_bit == 0)begin
                            cnt_bit = 7;
                            next_state = RD_ACK;
                        end
                        else cnt_bit = cnt_bit - 1;
                    end
                 end
                 RD_ACK   :begin
                    //1 이면 읽기
                    //0 이면 쓰기 
                    //정보를 받으면 슬레이브가 잘 받았다고 신호를 보냄 ACK신호 
                    //안 읽을 거임
                    //끊지 않고 값을 바로 받았으니 쓰기 바로시작 으로 변경
                    if(scl_nedge)sda = 'bz;
                    if(scl_pedge)begin
                        if(stop_flag)begin
                            stop_flag = 0;
                            next_state = SCL_STOP;
                        end
                        else begin
                            stop_flag = 1;
                            next_state = SEND_DATA;
                        end
                    end
                 end
                 SEND_DATA:begin
                 
                    if(scl_nedge)sda = data[cnt_bit];
                    if(scl_pedge)begin
                        if(cnt_bit == 0)begin
                            cnt_bit = 7;
                            next_state = RD_ACK;
                        end
                        else cnt_bit = cnt_bit - 1;
                    end
                    
                 end
                 SCL_STOP :begin
                    //데이터 까지 다 받고 SDA을 0으로 떨어트리고 
                    //SCL클락 0에서 
                    if(scl_nedge)sda = 0;
                    if(scl_pedge)next_state = COMM_STOP;
                 end
                 COMM_STOP:begin
                    //scl상승 엣지에서 
                    //SDA 상승엣지 
                    //통신은 한 클락에 10us이고
                    //이미 10ns마다 크락을 주면서 동작을 하기 때문에
                    //보드 기준으로 통신데이터 속도가 느림으로
                    //일정시간 기다림 기준을 추가
                    
                    //5us 이상 필요
                    //scl_e = 0 을 주면 바로 scl이 1이됨 
                    //클락은 1유지에서
                    
                    //3us 기다림 
                    if(count_usec5 >= 3)begin
                        scl_e = 0;
                        sda = 1; //스톱비트 주고
                        next_state = IDLE;  //다시 원래 상태로 돌아옴
                    end
                 end
                 default   :next_state = IDLE;
            
            endcase
        
        end
    end
    
endmodule

module i2c_lcd_send_byte(
    input clk, reset_p,
    input [6:0] addr,
    input [7:0] send_buffer,
    input send, rs,
    output scl, sda,
    output reg busy,
    output [15:0] led
);

    localparam IDLE                     = 6'b00_0001;
    localparam SEND_HIGH_NIBBLE_DISABLE = 6'b00_0010;
    localparam SEND_HIGH_NIBBLE_ENABLE  = 6'b00_0100;
    localparam SEND_LOW_NIBBLE_DISABLE  = 6'b00_1000;
    localparam SEND_LOW_NIBBLE_ENABLE   = 6'b01_0000;
    localparam SEND_DISABLE             = 6'b10_0000;
    
    wire clk_usec_nedge;
    clock_usec usec_clk(.clk(clk), .reset_p(reset_p), 
                        .clk_usec_nedge(clk_usec_nedge));
    wire send_pedge;
    edge_detector_p ed_start(.clk(clk), .reset_p(reset_p),
                       .cp(send), .p_edge(send_pedge));

    // 기존 us 카운터는 유지 (구조 보존)
   reg [21:0] count_usec;
    reg count_usec_e;
    always @(negedge clk, posedge reset_p)begin
        if(reset_p)count_usec = 0;
        else if(clk_usec_nedge && count_usec_e)count_usec = count_usec + 1;
        else if(!count_usec_e)count_usec = 0;
    end 

    // ---------------- I2C ----------------
    reg  [7:0] data;
    reg        comm_start;
    wire       i2c_busy;

    // 🔥 comm_start 펄스화
    
   I2C_master master(clk, reset_p, addr, data, 1'b0, 
                                comm_start, scl, sda, i2c_busy, led);  
                                
     reg [5:0] state, next_state;
    always @(negedge clk, posedge reset_p)begin
        if(reset_p)state = IDLE;
        else state = next_state;
    end
  

    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            next_state = IDLE;
            comm_start = 0;
            count_usec_e = 0;
            data = 0;
            busy = 0;
        end
        else begin
            case(state)
                IDLE                    :begin
                    busy = 0;
                    if(send_pedge)begin
                        busy = 1;
                        next_state = SEND_HIGH_NIBBLE_DISABLE;
                    end
                end
                SEND_HIGH_NIBBLE_DISABLE:begin
                    if(count_usec >= 22'd200)begin
                        comm_start = 0;
                        next_state =  SEND_HIGH_NIBBLE_ENABLE;
                        count_usec_e = 0;
                    end
                    else begin
                              //d7 d6 d5 d4  BL en, rw, rs    
                        data = {send_buffer[7:4], 3'b100, rs};
                        comm_start = 1;
                        count_usec_e = 1;
                    end
                end
                SEND_HIGH_NIBBLE_ENABLE :begin
                    if(count_usec >= 22'd200)begin
                        comm_start = 0;
                        next_state = SEND_LOW_NIBBLE_DISABLE;
                        count_usec_e = 0;
                    end
                    else begin
                        data = {send_buffer[7:4], 3'b110, rs};
                        comm_start = 1;
                        count_usec_e = 1;
                    end
                end
                SEND_LOW_NIBBLE_DISABLE :begin
                    if(count_usec >= 22'd200)begin
                        comm_start = 0;
                        next_state =  SEND_LOW_NIBBLE_ENABLE;
                        count_usec_e = 0;
                    end
                    else begin
                        data = {send_buffer[3:0], 3'b100, rs};
                        comm_start = 1;
                        count_usec_e = 1;
                    end
                end
                SEND_LOW_NIBBLE_ENABLE  :begin
                    if(count_usec >= 22'd200)begin
                        comm_start = 0;
                        next_state = SEND_DISABLE;
                        count_usec_e = 0;
                    end
                    else begin
                        data = {send_buffer[3:0], 3'b110, rs};
                        comm_start = 1;
                        count_usec_e = 1;
                    end
                end
                SEND_DISABLE            :begin
                    if(count_usec >= 22'd200)begin
                        comm_start = 0;
                        next_state = IDLE;
                        count_usec_e = 0;
                    end
                    else begin
                        data = {send_buffer[3:0], 3'b100, rs};
                        comm_start = 1;
                        count_usec_e = 1;
                    end
                end
                default: next_state = IDLE;
            endcase
        end
    end
                       
endmodule











