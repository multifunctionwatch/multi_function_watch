`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/09/2025 09:38:52 AM
// Design Name: 
// Module Name: exam03_var_module
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


module watch(
    input clk, reset_p,
    input start_pause,
    input hour_up_cntr,
    input min_up_cntr,
    input clear,
    output reg [7:0] min, hour);
    
    reg [7:0] sec;
    wire start_pause_pedge, hour_up_cntr_pedge, min_up_cntr_pedge, clear_pedge;
    
    button_cntr start_pause0(.clk(clk), .reset_p(reset_p),
                        .btn(start_pause), .btn_pedge(start_pause_pedge));
    button_cntr hour_up_cntr0(.clk(clk), .reset_p(reset_p),
                        .btn(hour_up_cntr), .btn_pedge(hour_up_cntr_pedge));
    button_cntr min_up_cntr0(.clk(clk), .reset_p(reset_p),
                        .btn(min_up_cntr), .btn_pedge(min_up_cntr_pedge));  
    button_cntr clear0(.clk(clk), .reset_p(reset_p),
                        .btn(clear), .btn_pedge(clear_pedge));   
                                             
    reg set_watch; // set이면 1 watch 면 0 
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)set_watch = 0;
        else if (start_pause_pedge)set_watch = ~set_watch;
    end
    
    
    integer cnt_sysclk;
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            cnt_sysclk = 0;
            sec = 0;
            min = 0;
            hour = 0;
        end    
        else begin
            if(set_watch)begin
                if(min_up_cntr_pedge)begin
                    if(min >= 59) min = 0;
                    else min = min + 1;
                end
                if(hour_up_cntr_pedge)begin
                    if(hour >= 23) hour = 0;
                    else hour = hour + 1;                
                end
                if(clear_pedge)begin
                    sec = 0;
                    min = 0;
                    hour = 0;
                end
            end
            else begin
                if(cnt_sysclk >= 27'd99_999_999)begin
                    cnt_sysclk = 0;
                    if(sec >= 59)begin
                        sec = 0;
                        if (min >= 59)begin 
                            min = 0;
                                if(hour >= 23) 
                                hour = 0;
                            else hour = hour + 1;
                        end
                        else min = min + 1;
                    end
                    else sec = sec + 1;
                end
                else cnt_sysclk = cnt_sysclk + 1;
            end
        end
    end
endmodule
