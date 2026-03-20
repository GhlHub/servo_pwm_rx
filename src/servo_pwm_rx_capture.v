`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/10/2026 05:59:22 AM
// Design Name: 
// Module Name: servo_pwm_rx_capture
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


module servo_pwm_rx_capture(
    input wire clk,
    input wire rst,
    input wire pwm_in,
    input wire [11:0] ui_clk_ticks,
    //input wire [11:0] frame_ui_ticks,
    output reg [11:0] pwm_rx_ui_ticks,
    output reg        pwm_rx_ui_ticks_dv
    );
    
wire [11:0] pwm_rx_ui_ticks_d; 
   
reg [11:0] pulse_clk_ticks;
reg [11:0] pulse_ui_ticks;
reg [2:0]  deglitch;
reg        pwm_in_meta;
reg        pwm_in_sync;
reg pwm_in_deglitch;
reg [1:0]  pwm_in_pipeline;
reg        pulse_det;

wire pwm_negedge_det;
wire pwm_posedge_det;
wire pulse_ui_det;
wire ui_clk_ticks_valid;
wire measure_rst;

reg pwm_negedge_det_d1;

assign pwm_negedge_det =  pwm_in_pipeline[1] & ~pwm_in_pipeline[0];
assign pwm_posedge_det = ~pwm_in_pipeline[1] &  pwm_in_pipeline[0];
assign ui_clk_ticks_valid = |ui_clk_ticks;
assign measure_rst    = rst | ~ui_clk_ticks_valid;
assign pulse_ui_det   = (pulse_clk_ticks == ui_clk_ticks);


always@(posedge clk)
begin
    if(measure_rst)
        begin
            deglitch           <= 3'b000;
            pwm_in_meta        <= 1'b0;
            pwm_in_sync        <= 1'b0;
            pwm_in_pipeline    <= 2'b00;
            pwm_negedge_det_d1 <= 1'b0;
        end
    else
        begin
            pwm_in_meta        <= pwm_in;
            pwm_in_sync        <= pwm_in_meta;
            deglitch           <= {deglitch[1:0], pwm_in_sync};             // deglitch only after synchronizing the async input
            pwm_in_pipeline    <= {pwm_in_pipeline[0], pwm_in_deglitch};    // after deglitch, pipeline for posedge and negedge detection
            pwm_negedge_det_d1 <=  pwm_negedge_det;                         // one clock delayed version of negedge detect
        end
        
    casez({measure_rst, deglitch})  // Majority voting for deglitch
        4'b1???:    pwm_in_deglitch <= 0;
        4'b0011,
        4'b0101,
        4'b0110,
        4'b0111:    pwm_in_deglitch <= 1;
        4'b0100,
        4'b0010,
        4'b0001,
        4'b0000:    pwm_in_deglitch <= 0;
        default:    pwm_in_deglitch <= pwm_in_deglitch;
    endcase
end

always@(posedge clk)
begin
    casez({measure_rst, pwm_posedge_det, pwm_negedge_det})  //
        3'b1??:  pulse_det <= 1'b0;
        3'b010:  pulse_det <= 1'b1;
        3'b001:  pulse_det <= 1'b0;
        default: pulse_det <= pulse_det;
    endcase
    
    casez({measure_rst, pulse_det, pwm_negedge_det_d1, pulse_ui_det, pwm_negedge_det})
        5'b1????,
        5'b00???:    pulse_clk_ticks <= 0;
        5'b01000:    pulse_clk_ticks <= pulse_clk_ticks + 1;
        5'b0101?:    pulse_clk_ticks <= 0;
        5'b011??:    pulse_clk_ticks <= 0;
        default:     pulse_clk_ticks <= pulse_clk_ticks;
    endcase
    
    casez({measure_rst, pulse_det, pulse_ui_det})
        3'b1??,
        3'b00?:   pulse_ui_ticks <= 0;
        3'b011:   pulse_ui_ticks <= pulse_ui_ticks + 1;
        default:  pulse_ui_ticks <= pulse_ui_ticks;
    endcase
    
    casez({measure_rst, pwm_negedge_det_d1})    // Need to delay the dv by one clock to register the ui ticks after rounding
        2'b1?:  pwm_rx_ui_ticks_dv <= 1'b0;
        2'b01:  pwm_rx_ui_ticks_dv <= 1'b1;
        default:pwm_rx_ui_ticks_dv <= 1'b0;
    endcase
    
    casez({measure_rst, pwm_negedge_det_d1})
        2'b1?: pwm_rx_ui_ticks <= 0;
        2'b01: pwm_rx_ui_ticks <= pwm_rx_ui_ticks_d;
        default: pwm_rx_ui_ticks <= pwm_rx_ui_ticks;
    endcase
end

wire [12:0] ui_clk_ticks_rounded;
wire [12:0] rounded_pulse_clk_ticks;

assign ui_clk_ticks_rounded   = {1'b0, ui_clk_ticks} + 13'd1;
assign rounded_pulse_clk_ticks = {1'b0, pulse_clk_ticks} + (ui_clk_ticks_rounded >> 1);

// Decide if we want to round up the number of UI ticks
assign pwm_rx_ui_ticks_d = (rounded_pulse_clk_ticks >= {1'b0, ui_clk_ticks}) ? pulse_ui_ticks + 1'b1 : pulse_ui_ticks;

    
endmodule
