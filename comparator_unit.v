`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/25/2018 02:03:43 PM
// Design Name: 
// Module Name: comparator_unit
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
module comparator_unit(
    clk,
    rst_n,
    data_in_a,
    data_in_b,
    data_out
    );
    
parameter FEATURE_WIDTH = 32;    

input  clk;
input  rst_n;
input  data_in_a;
input  data_in_b;
output data_out;



wire  signed [ FEATURE_WIDTH - 1 : 0 ]             data_in_a;
wire  signed [ FEATURE_WIDTH - 1 : 0 ]             data_in_b;
reg   signed [ FEATURE_WIDTH - 1 : 0 ]             data_out;



always @(posedge clk or negedge rst_n)
    begin
       if(!rst_n)
           data_out <= 0;
       else
           data_out <= (data_in_a >= data_in_b)?data_in_a:data_in_b;
    end
endmodule





