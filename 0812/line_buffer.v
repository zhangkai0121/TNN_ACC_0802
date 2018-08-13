`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/11/2018 05:32:39 PM
// Design Name: 
// Module Name: line_buffer
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
module line_buffer#(
    parameter DATA_WIDTH = 32,
    parameter KERNEL_SIZE = 5    
)(
    input wire                                      clk,
    input wire                                      rst_n,
    input wire                                      enable,
    input wire [DATA_WIDTH - 1 : 0 ]                data_in,
    output wire [DATA_WIDTH * KERNEL_SIZE - 1 : 0 ] data_out
    );
wire [DATA_WIDTH - 1 : 0 ] data_wire[KERNEL_SIZE - 2 : 0];

shift_ram ram0(                         //buffer0
            .D(data_in), 
            .CLK(clk), 
            .CE(enable), 
            .Q(data_wire[0])
              );
                       
genvar i;
generate 
    for(i = 0; i < KERNEL_SIZE-2 ; i = i+1) begin:buffer_wire    //buffer1 ---> (KERNEL_SIZE-2)
        shift_ram ram1(
                     .D(data_wire[i]),
                     .CLK(clk),
                     .CE(enable),
                     .Q(data_wire[i+1])
                       );
    end
endgenerate

generate
   for(i = 0; i < KERNEL_SIZE-1 ; i = i+1) begin:convert
        //assign data_out[(i+2) * DATA_WIDTH - 1 : (i+1) * DATA_WIDTH] = data_wire[i];
        assign data_out[i * DATA_WIDTH + DATA_WIDTH - 1 : i * DATA_WIDTH] = data_wire[KERNEL_SIZE - 2 - i];
   end 
endgenerate

//assign data_out[DATA_WIDTH-1 : 0] = data_in;
assign data_out[DATA_WIDTH * KERNEL_SIZE - 1 : DATA_WIDTH * KERNEL_SIZE - DATA_WIDTH ] = data_in;

endmodule