`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/28/2018 10:45:54 PM
// Design Name: 
// Module Name: top
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


module top(
        input        clk,
        input        rst_n
        );

reg      [9:0]      i_mem_addr;
wire     [99:0]     i_mem_dout;


reg                 CLP_enable;
reg      [99:0]     ctr;
wire                CLP_state;      //0 CLP idle    1 CLP busy
reg                 CLP_state_p;



i_memory_gen i_memory(
                .clka(clk),
                .ena(1),
                .addra(i_mem_addr),  // input wire [9 : 0] addra
                .douta(i_mem_dout)  // output wire [99 : 0] douta
            );

always@(posedge clk or negedge rst_n)
    if(!rst_n)
        CLP_state_p <= 0;
    else
        CLP_state_p <= CLP_state;

always@(posedge clk or negedge rst_n)
    if(!rst_n)
        i_mem_addr <= 0;
    else
        if((CLP_state == 0) && (CLP_state_p == 1))
            i_mem_addr <= i_mem_addr + 1;
        else
            i_mem_addr <= i_mem_addr;  



reg  [3:0]state;


always@(posedge clk or negedge rst_n)
    if(!rst_n)
        begin
            CLP_enable <= 0;
            ctr <= 0;
            state <= 0;
        end
    else
        begin
            case(state)
                0:begin
                    state <= 1;
                end    
                1:begin
                    CLP_enable<=1;
                    ctr <= i_mem_dout;
                    state <= 2;
                end
                2:begin
                    if(CLP_state == 1)
                        CLP_enable <= 0;
                    else
                        CLP_enable <= CLP_enable;
                    if(CLP_enable == 0)
                        state <= 3;
                    else 
                        state <= state;            
                end
                3:begin
                    if(CLP_state == 0)
                        state <= 0;
                    else
                        state <= state;
                end
            endcase
        end
 
 
 
CLP_ctr CLP_ctr0(
            .clk(clk),
            .rst_n(rst_n),
            .enable(CLP_enable),
            .instruction(ctr),
            .state(CLP_state)
            );    
        
        
reg [12:0] cnt_for_test;

always@(posedge clk or negedge rst_n)
    if(!rst_n)
        cnt_for_test <= 0;
    else
        cnt_for_test <= cnt_for_test + 1;

endmodule




