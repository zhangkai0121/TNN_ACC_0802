`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/02/2018 12:12:24 PM
// Design Name: 
// Module Name: weight_mem_ctr
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


module weight_mem_ctr#(
    parameter Tn = 4,
    parameter Tm = 8,
    parameter KERNEL_SIZE = 5,
    parameter KERNEL_WIDTH = 2    
)(
    input wire                                                                      clk,
    input wire                                                                      rst_n,
    input wire                                                                      state,
    input wire [9:0]                                                                weight_mem_init_addr,
    input wire [9:0]                                                                weight_amount,
    output wire [ Tn * Tm * KERNEL_SIZE * KERNEL_SIZE * KERNEL_WIDTH - 1 : 0 ]      weight_wire
    );

genvar i,j,k,x,y,z;
reg     [8:0]                                                               weight_mem_addr;
wire    [49:0]                                                              weight_mem_dout;

reg                                                                         weight_mem_read_enable;
reg                                                                         weight_mem_read_enable_p;
reg                                                                         weight_mem_read_enable_p2;

reg     [ KERNEL_SIZE * KERNEL_SIZE * KERNEL_WIDTH - 1 : 0 ]                weight_in_buf[Tn * Tm - 1 : 0];
reg     [8:0]                                                               weight_mem_read_cnt; 
reg                                                                         weight_wire_ready;
always@(posedge clk or negedge rst_n)
    if(!rst_n)
        weight_mem_read_enable <= 0;
    else
        if(state == 0)
            weight_mem_read_enable <= 0;
        else
            if(weight_wire_ready == 0)
                weight_mem_read_enable <= 1;
            else 
                weight_mem_read_enable <= 0;


always@(posedge clk or negedge rst_n)
    if(!rst_n)
        begin
            weight_mem_read_enable_p <= 0;
            weight_mem_read_enable_p2 <= 0;
        end
    else
        begin
            weight_mem_read_enable_p <= weight_mem_read_enable;
            weight_mem_read_enable_p2 <= weight_mem_read_enable_p;
        end

always@(posedge clk or negedge rst_n)
    if(!rst_n)
        begin
            weight_mem_addr <= 0;
        end
    else
        begin
            if((weight_mem_read_enable_p == 0) && (weight_mem_read_enable == 1))
                begin
                    weight_mem_addr <= weight_mem_init_addr[8:0];
                end
            else if(weight_mem_read_enable == 1)
                begin
                    weight_mem_addr <= weight_mem_addr + 1;
                end
        end

always@(posedge clk or negedge rst_n)
    if(!rst_n)
         weight_mem_read_cnt <= 0;    
    else
        begin
            if(state == 0)
                weight_mem_read_cnt <= 0;
            else
                if((weight_mem_read_enable_p2 == 0) && (weight_mem_read_enable_p == 1))
                    begin
                        weight_mem_read_cnt <= 0;
                    end
                else if(weight_mem_read_enable_p2 == 1)
                    begin
                        weight_mem_read_cnt <= weight_mem_read_cnt + 1;
                    end
        end

always@(posedge clk or negedge rst_n)
    if(!rst_n)
        ;
    else
        if(weight_mem_read_enable_p2 == 1)
            begin
                weight_in_buf[weight_mem_read_cnt] <= weight_mem_dout;
            end
        else
            ;


always@(posedge clk or negedge rst_n)
    if(!rst_n)
        begin
            weight_wire_ready <= 0;
        end
    else 
        begin
            if(state == 0)
                weight_wire_ready <= 0;
            else
                if(weight_mem_read_cnt >= weight_amount - 4)
                    weight_wire_ready <=1;
                else
                    weight_wire_ready <= 0;
        end

weight_mem_gen weight_mem0(
  .clka(clk),    // input wire clka
  .ena(weight_mem_read_enable_p),      // input wire ena
  .addra(weight_mem_addr),  // input wire [8 : 0] addra
  .douta(weight_mem_dout)  // output wire [49 : 0] douta
);
generate
    for(i = 0 ; i < Tm ; i = i + 1) begin:weight_wire_i
        for(j = 0 ; j < Tn ; j = j + 1) begin:weight_wire_j
            for(k = 0 ; k < KERNEL_SIZE * KERNEL_SIZE ; k = k + 1) begin:weight_wire_k
                assign weight_wire[i * Tn * KERNEL_SIZE * KERNEL_SIZE * KERNEL_WIDTH + j * KERNEL_SIZE * KERNEL_SIZE * KERNEL_WIDTH + k * KERNEL_WIDTH + KERNEL_WIDTH - 1 :
                                   i * Tn * KERNEL_SIZE * KERNEL_SIZE * KERNEL_WIDTH + j * KERNEL_SIZE * KERNEL_SIZE * KERNEL_WIDTH + k * KERNEL_WIDTH ]
                       = weight_in_buf[i*Tn+j][( 24 - k ) * KERNEL_WIDTH + KERNEL_WIDTH - 1:( 24 - k ) * KERNEL_WIDTH];
            end
        end
    end
endgenerate
        
endmodule