`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/29/2018 07:46:24 PM
// Design Name: 
// Module Name: CLP_ctr
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
//   conv    788
//   ip       39
//////////////////////////////////////////////////////////////////////////////////


module CLP_ctr#(
    parameter Tn = 4,
    parameter Tm = 8,
    parameter KERNEL_SIZE = 5,
    parameter KERNEL_WIDTH = 2,
    parameter KERNEL_ADD_WIDTH = 15,
    parameter KERNEL_BUF_ADDR = 10,

    parameter FEATURW_SIZE = 28,
    parameter FEATURE_WIDTH = 32,
    parameter FEATURE_ADD_WIDTH = 12,

    parameter SCALER_WIDTH = 32,
    parameter SCALER_ADD_WIDTH = 2
)(
    input   wire                                        clk,
    input   wire                                        rst_n,
    input   wire                                        enable,
    input   wire    [99:0]                              instruction,
    output  reg                                         state
    );
genvar i,j,k,x,y,z;

reg     [3:0]           CLP_type;
reg     [14:0]          featrue_mem_init_addr;
reg     [9:0]           feature_amount;
reg     [9:0]           weight_mem_init_addr;
reg     [9:0]           weight_amount;
reg     [9:0]           scaler_mem_addr;
reg     [9:0]           output_data_addr_init;

reg     [7:0]           CLP_row_cnt;
reg                     CLP_row_cnt_start;
reg     [11:0]          CLP_ctr_cnt;

reg                     CLP_enable;
reg                     CLP_enable_p;
reg                     CLP_data_ready;
wire                    CLP_state;
wire                    CLP_output_flag;
wire   [ Tm * FEATURE_WIDTH - 1 : 0 ]                     CLP_output;

always@(posedge clk or negedge rst_n)
    if(!rst_n)
        CLP_ctr_cnt <= 0;
    else
        if(state == 0)
            CLP_ctr_cnt <= 0;
        else
            CLP_ctr_cnt <= CLP_ctr_cnt + 1;    
  
 always@(posedge clk or negedge rst_n)
    if(!rst_n)
        begin
            state <= 0;
        end 
    else
        begin
            if(enable == 1)
                state <= 1;
            else
                if(CLP_ctr_cnt == 788)
                    state <= 0;
                else
                    state <= state;
        end
        
always@(posedge clk or negedge rst_n)
    if(!rst_n)
        CLP_enable_p <= 0;
    else 
        CLP_enable_p <= CLP_enable;
   
 
always@(posedge clk or negedge rst_n)
    if(!rst_n)
        begin
            CLP_row_cnt <= 0;
        end 
    else
        if((CLP_enable_p == 0) && (CLP_enable == 1))
            CLP_row_cnt <= 0;    
        else 
            if(CLP_data_ready == 1)
                CLP_row_cnt <= CLP_row_cnt + 1; 
            else
                CLP_row_cnt <= CLP_row_cnt;
       
       
 
 always@(posedge clk or negedge rst_n)
    if(!rst_n)
        CLP_data_ready <= 0;
    else 
        if(CLP_ctr_cnt == 119)
            CLP_data_ready <= 1;
        else if(CLP_ctr_cnt == 788)
            CLP_data_ready <= 0;

    
always@(posedge clk or negedge rst_n)
    if(!rst_n)
        CLP_enable <= 0;
    else 
//        if(CLP_type[3] == 1)
//            begin
//                if(CLP_ctr_cnt == 42)
//                    CLP_enable <= 1;
//                else
//                    CLP_enable <= 0;        
//            end
//        else
            begin
                if(CLP_ctr_cnt == 119)
                    CLP_enable <= 1;
                else if(CLP_ctr_cnt >= 788)
                    CLP_enable <= 0;
                else        
                    if(CLP_row_cnt== 22) 
                        CLP_enable <= 0;
                    else if(CLP_row_cnt == 26)
                        CLP_enable <= 1;     
            end

 
    
 always@(posedge clk or negedge rst_n)
    if(!rst_n)
        begin
            CLP_type <= 0;
            featrue_mem_init_addr <= 0;
            feature_amount <= 0;
            weight_mem_init_addr <= 0;
            weight_amount <= 0;
            scaler_mem_addr <= 0;
            output_data_addr_init<=0;
        end   
    else
        begin
            if(state == 1)
                begin
                    CLP_type <= instruction[3:0];
                    featrue_mem_init_addr <= instruction[84:70];
                    feature_amount <= instruction[69:60];
                    weight_mem_init_addr <= instruction[59:50];
                    weight_amount <= instruction[49:40];
                    scaler_mem_addr <= instruction[39:30];   
                    output_data_addr_init <= instruction[29:20];           
                end
            else
                ;
        end



                    
wire  [ Tn * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH - 1 : 0 ]                   feature_wire;    
wire  [ SCALER_WIDTH - 1:0  ]                                                      scaler_wire;
wire  [ Tn * Tm * KERNEL_SIZE * KERNEL_SIZE * KERNEL_WIDTH - 1 : 0 ]               weight_wire;

featrue_mem_ctr featrue_mem_ctr0(
           .clk(clk),
           .rst_n(rst_n),
           .CLP_type(CLP_type),
           .state(state),
           .feature_amount(feature_amount),
           .featrue_mem_init_addr(featrue_mem_init_addr),
           .output_data_addr_init(output_data_addr_init),
           .CLP_output_flag(CLP_output_flag),
           .CLP_output(CLP_output),
           .feature_wire(feature_wire)
    );



weight_mem_ctr weight_mem_ctr0(
        .clk(clk),
        .rst_n(rst_n),
        .state(state),
        .weight_mem_init_addr(weight_mem_init_addr),
        .weight_amount(weight_amount),
        .weight_wire(weight_wire)
    );

scaler_ctr scaler_ctr0(
        .clk(clk),
        .rst_n(rst_n),
        .state(state),
        .scaler_mem_addr(scaler_mem_addr),
        .scaler_wire(scaler_wire)
        );

CLP CLP0( 
        .clk(clk),
        .rst_n(rst_n),
        .feature_in(feature_wire),
        .weight_in(weight_wire),
        .weight_scaler(scaler_wire),
        .bias_in(0),
        .ctr(CLP_type),
        .addr_clear(CLP_data_ready),
        .enable(CLP_enable),
        .bias_out_feature_size(24),
        .out_valid(CLP_output_flag),
        .feature_out(CLP_output)
    );

endmodule
