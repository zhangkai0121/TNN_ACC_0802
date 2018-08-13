`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/02/2018 02:27:25 PM
// Design Name: 
// Module Name: featrue_mem_ctr
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


module featrue_mem_ctr#(
    parameter Tn = 4,
    parameter Tm = 8,
    parameter FEATURW_SIZE = 28,
    parameter FEATURE_WIDTH = 32,
    parameter FEATURE_ADD_WIDTH = 12,
    parameter KERNEL_SIZE = 5
)(
    input wire                                                                    clk,
    input wire                                                                    rst_n,
    input wire   [3:0]                                                            CLP_type,
    input wire                                                                    state,
    input wire   [9:0]                                                            feature_amount,
    input wire   [14:0]                                                           featrue_mem_init_addr,
    input wire   [9:0]                                                            output_data_addr_init,
    input wire                                                                    CLP_output_flag,
    input wire   [ Tm * FEATURE_WIDTH - 1 : 0 ]                                   CLP_output,
    output wire  [ Tn * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH - 1 : 0 ]       feature_wire
    );
    
genvar i,j,k,x,y,z;

reg                     feature_mem_write_enable;
reg                     feature_mem_write_enable_p;
reg     [9:0]           feature_mem_write_addr;
reg     [9:0]           feature_mem_write_addr_n;
reg     [255:0]         feature_mem_write_data;

reg                     feature_mem_read_enable;
reg                     feature_mem_read_enable_p;
reg                     feature_read_ready;
reg     [10:0]          feature_mem_read_cnt;

reg     [10:0]          feature_mem_read_addr;
wire    [127:0]         feature_mem_read_data;


reg                     line_buffer_enable;


always@(posedge clk or negedge rst_n)
    if(!rst_n)
        feature_mem_read_enable <= 0;
    else 
        if(state == 0)
            feature_mem_read_enable <= 0;
        else
            if(feature_read_ready == 1)
                feature_mem_read_enable <= 0;
            else    
                feature_mem_read_enable <= 1;
            
always@(posedge clk or negedge rst_n)
    if(!rst_n)
        feature_mem_read_enable_p <= 0;
    else
        feature_mem_read_enable_p <= feature_mem_read_enable;     
 
always@(posedge clk or negedge rst_n)
    if(!rst_n)
        feature_mem_read_addr <= 0;          
    else
        if((feature_mem_read_enable_p == 0)&&(feature_mem_read_enable == 1))
            feature_mem_read_addr <= featrue_mem_init_addr;
        else if(feature_mem_read_enable_p == 1)
            feature_mem_read_addr <= feature_mem_read_addr + 1;
            
always@(posedge clk or negedge rst_n)
    if(!rst_n)
        feature_mem_read_cnt <= 0;
    else
        if(state == 0)
            feature_mem_read_cnt <= 0;
        else         
            if(feature_mem_read_enable_p == 1)
                feature_mem_read_cnt <= feature_mem_read_cnt + 1;
            else
                feature_mem_read_cnt <= feature_mem_read_cnt;            
        
always@(posedge clk or negedge rst_n)
    if(!rst_n) 
        feature_read_ready <= 0;
    else 
        if(feature_mem_read_cnt >= feature_amount-2)
            feature_read_ready <= 1;
        else
            feature_read_ready <= 0;           

always@(posedge clk or negedge rst_n)
    if(!rst_n)
        line_buffer_enable <= 0;
    else
        if(state == 0)
            line_buffer_enable <= 0;
        else
            if((feature_mem_read_enable_p == 0)&&(feature_mem_read_enable == 1))
                line_buffer_enable <= 1;
            else
                line_buffer_enable <= line_buffer_enable;
               
                
 featrure_memory_gen feature_memory_test (
              .clka(clk),    // input wire clka
              .ena(feature_mem_write_enable),      // input wire ena
              .wea( ),      // input wire [0 : 0] wea
              .addra(feature_mem_write_addr),  // input wire [9 : 0] addra
              .dina(feature_mem_write_data),    // input wire [255 : 0] dina
              .clkb(clk),    // input wire clkb
              .enb(feature_mem_read_enable),      // input wire enb
              .addrb(feature_mem_read_addr),  // input wire [10 : 0] addrb
              .doutb(feature_mem_read_data)  // output wire [127 : 0] doutb
            );   
 
reg  [ FEATURE_WIDTH - 1 : 0 ]                                          feature_in_buf[Tn * KERNEL_SIZE * KERNEL_SIZE - 1 : 0];
//reg  [ FEATURE_WIDTH - 1 : 0 ]                                          feature_in_buf1[Tn * KERNEL_SIZE * KERNEL_SIZE - 1 : 0];
wire [ Tn * FEATURE_WIDTH * KERNEL_SIZE - 1 : 0 ]                       feature_transfer_wire;
            
            
generate
for(i = 0 ; i < Tn; i = i+1) begin:data_transfer
    line_buffer line_buffer0(
                    .clk(clk),
                    .rst_n(rst_n),
                    .enable(line_buffer_enable),
                    .data_in(feature_mem_read_data[(i+1) * FEATURE_WIDTH - 1 : i * FEATURE_WIDTH]),
                    .data_out(feature_transfer_wire[(i+1) * FEATURE_WIDTH * KERNEL_SIZE - 1 : i * FEATURE_WIDTH * KERNEL_SIZE])
                    );
end
endgenerate
generate
for(i = 0 ; i < Tn; i = i + 1) begin:feature_in_buf_i
    for(j = 0 ; j < KERNEL_SIZE; j = j + 1) begin:feature_in_buf_j
        always@(posedge clk or negedge rst_n)
            if(!rst_n)
                feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE  + j * KERNEL_SIZE + KERNEL_SIZE - 1] <= 0;
            else
                feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE  + j * KERNEL_SIZE + KERNEL_SIZE - 1] 
                <= feature_transfer_wire[i * KERNEL_SIZE * FEATURE_WIDTH + j * FEATURE_WIDTH + FEATURE_WIDTH - 1 : i * KERNEL_SIZE * FEATURE_WIDTH + j * FEATURE_WIDTH];
        for(k = 1 ; k < KERNEL_SIZE; k = k + 1) begin:feature_in_buf_k
            always@(posedge clk or negedge rst_n) 
                if(!rst_n)
                    feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE  + j * KERNEL_SIZE + k - 1] <= 0;
                else
                    feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE  + j * KERNEL_SIZE + k - 1] <= feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE  + j * KERNEL_SIZE + k];
        end
    end
end
endgenerate
//generate
//for(i = 0 ; i < Tn; i = i + 1) begin:feature_in_buf_i
//    for(j = 0 ; j < KERNEL_SIZE; j = j + 1) begin:feature_in_buf_j
//        always@(posedge clk or negedge rst_n)
//            if(!rst_n)
//                feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE  + j * KERNEL_SIZE + KERNEL_SIZE - 1] <= 0;
//            else
//                if(CLP_type[3] == 0) 
//                    feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE  + j * KERNEL_SIZE + KERNEL_SIZE - 1] 
//                    <= feature_transfer_wire[i * KERNEL_SIZE * FEATURE_WIDTH + j * FEATURE_WIDTH + FEATURE_WIDTH - 1 : i * KERNEL_SIZE * FEATURE_WIDTH + j * FEATURE_WIDTH];
//                else
//                    ;
//        for(k = 1 ; k < KERNEL_SIZE; k = k + 1) begin:feature_in_buf_k
//            always@(posedge clk or negedge rst_n) 
//                if(!rst_n)
//                    feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE  + j * KERNEL_SIZE + k - 1] <= 0;
//                else
//                    if(CLP_type[3] == 0)
//                        feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE  + j * KERNEL_SIZE + k - 1] <= feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE  + j * KERNEL_SIZE + k];
//                    else
//                        ;
//        end
//    end
//end
//endgenerate

//generate
//    for(i = 0 ; i < Tn; i = i + 1) begin:feature_in_buf1_i
//        always@(posedge clk or negedge rst_n)
//            if(!rst_n)
//                feature_in_buf1[i * KERNEL_SIZE * KERNEL_SIZE + KERNEL_SIZE * KERNEL_SIZE - 1] <= 0;
//            else
//                if((CLP_type[3] == 1)&& (feature_mem_read_cnt <= feature_amount))
//                    feature_in_buf1[i * KERNEL_SIZE * KERNEL_SIZE + KERNEL_SIZE * KERNEL_SIZE - 1] <= feature_mem_read_data[i * FEATURE_WIDTH + FEATURE_WIDTH - 1 : i * FEATURE_WIDTH];
//                else
//                    ;
//        for(j = 1 ; j < KERNEL_SIZE * KERNEL_SIZE ; j = j + 1) begin:  feature_in_buf1_i
//            always@(posedge clk or negedge rst_n)
//                if(!rst_n)
//                    feature_in_buf1[i * KERNEL_SIZE * KERNEL_SIZE + j - 1 ] <= 0;
//                else
//                    if((CLP_type[3] == 1)&& (feature_mem_read_cnt <= feature_amount))
//                        feature_in_buf1[i * KERNEL_SIZE * KERNEL_SIZE + j - 1 ] <= feature_in_buf1[i * KERNEL_SIZE * KERNEL_SIZE + j];
//                    else
//                        ;
//        end
//    end
//endgenerate

//generate
//for(i = 0 ; i <Tn ; i = i + 1) begin:feature_wire_i
//    for(j = 0 ; j < KERNEL_SIZE; j = j + 1) begin:feature_wire_j
//        for(k = 0 ; k < KERNEL_SIZE; k = k + 1) begin:feature_wire_k
//            assign feature_wire[i * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH + j * KERNEL_SIZE * FEATURE_WIDTH + k * FEATURE_WIDTH + FEATURE_WIDTH - 1 : 
//                                i * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH + j * KERNEL_SIZE * FEATURE_WIDTH + k * FEATURE_WIDTH]
//                    = (CLP_type[3] == 0) ?  feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE + j * KERNEL_SIZE + k] : feature_in_buf1[i * KERNEL_SIZE * KERNEL_SIZE + j * KERNEL_SIZE + k];
//        end
//    end
//end
//endgenerate

generate
for(i = 0 ; i <Tn ; i = i + 1) begin:feature_wire_i
    for(j = 0 ; j < KERNEL_SIZE; j = j + 1) begin:feature_wire_j
        for(k = 0 ; k < KERNEL_SIZE; k = k + 1) begin:feature_wire_k
            assign feature_wire[i * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH + j * KERNEL_SIZE * FEATURE_WIDTH + k * FEATURE_WIDTH + FEATURE_WIDTH - 1 : 
                                i * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH + j * KERNEL_SIZE * FEATURE_WIDTH + k * FEATURE_WIDTH]
                    = feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE + j * KERNEL_SIZE + k];
        end
    end
end
endgenerate
always@(posedge clk or negedge rst_n)
    if(!rst_n)
        feature_mem_write_enable <= 0;
    else 
        if(state == 0)
            feature_mem_write_enable <= 0;
        else
            feature_mem_write_enable <= 1;
 
always@(posedge clk or negedge rst_n)
    if(!rst_n)
        feature_mem_write_enable_p <= 0;
    else
        feature_mem_write_enable_p <= feature_mem_write_enable;             



always@(posedge clk or negedge rst_n)
    if(!rst_n)
        begin
            feature_mem_write_addr_n <= 0;
            feature_mem_write_addr <= 0;
        end
    else 
        if(state == 0)
            begin
                feature_mem_write_addr_n <= 0;
                feature_mem_write_addr <= 0;
            end
        else    
            if((feature_mem_write_enable_p == 0) && (feature_mem_write_enable == 1))
                feature_mem_write_addr_n <= output_data_addr_init;
            else
                if(CLP_output_flag == 1)
                    begin
                        feature_mem_write_addr_n <= feature_mem_write_addr_n + 1;
                        feature_mem_write_data <= CLP_output;
                        feature_mem_write_addr<=feature_mem_write_addr_n;
                    end
                else
                    ;        
endmodule