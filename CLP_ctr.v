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


module CLP_ctr(
        clk,
        rst_n,
        enable,
        instruction,
        state
    );

parameter Tn = 4;
parameter Tm = 8;
parameter KERNEL_SIZE = 5;
parameter KERNEL_WIDTH = 2;
parameter KERNEL_ADD_WIDTH = 15;
parameter KERNEL_BUF_ADDR = 10;

parameter FEATURW_SIZE = 28;
parameter FEATURE_WIDTH = 32;
parameter FEATURE_ADD_WIDTH = 12;

parameter SCALER_WIDTH = 32;
parameter SCALER_ADD_WIDTH = 2;

genvar i,j,k,x,y,z;

input           clk;
input           rst_n;
input           enable;
input [99:0]    instruction;
output          state;


reg                     state;


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
                if(CLP_ctr_cnt == 39)
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
        else if(CLP_ctr_cnt == 39)
            CLP_data_ready <= 0;

    
always@(posedge clk or negedge rst_n)
    if(!rst_n)
        CLP_enable <= 0;
    else 
        if(CLP_ctr_cnt == 119)
            CLP_enable <= 1;
        else if(CLP_ctr_cnt >= 39)
            CLP_enable <= 0;
        else        
            if(CLP_row_cnt== 22) 
                CLP_enable <= 0;
            else if(CLP_row_cnt == 26)
                CLP_enable <= 1;     
    
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




 
 

wire [ Tn * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH - 1 : 0 ]         feature_wire;
 
 
reg  [ FEATURE_WIDTH - 1 : 0 ]                                          feature_in_buf[Tn * KERNEL_SIZE * KERNEL_SIZE - 1 : 0];
reg  [ FEATURE_WIDTH - 1 : 0 ]                                          feature_in_buf1[Tn * KERNEL_SIZE * KERNEL_SIZE - 1 : 0];
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
                if(CLP_type[3] == 0) 
                    feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE  + j * KERNEL_SIZE + KERNEL_SIZE - 1] 
                    <= feature_transfer_wire[i * KERNEL_SIZE * FEATURE_WIDTH + j * FEATURE_WIDTH + FEATURE_WIDTH - 1 : i * KERNEL_SIZE * FEATURE_WIDTH + j * FEATURE_WIDTH];
                else
                    ;
        for(k = 1 ; k < KERNEL_SIZE; k = k + 1) begin:feature_in_buf_k
            always@(posedge clk or negedge rst_n) 
                if(!rst_n)
                    feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE  + j * KERNEL_SIZE + k - 1] <= 0;
                else
                    if(CLP_type[3] == 0)
                        feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE  + j * KERNEL_SIZE + k - 1] <= feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE  + j * KERNEL_SIZE + k];
                    else
                        ;
        end
    end
end
endgenerate

generate
    for(i = 0 ; i < Tn; i = i + 1) begin:feature_in_buf1_i
        always@(posedge clk or negedge rst_n)
            if(!rst_n)
                feature_in_buf1[i * KERNEL_SIZE * KERNEL_SIZE + KERNEL_SIZE * KERNEL_SIZE - 1] <= 0;
            else
                if((CLP_type[3] == 1)&& (feature_mem_read_cnt <= feature_amount))
                    feature_in_buf1[i * KERNEL_SIZE * KERNEL_SIZE + KERNEL_SIZE * KERNEL_SIZE - 1] <= feature_mem_read_data[i * FEATURE_WIDTH + FEATURE_WIDTH - 1 : i * FEATURE_WIDTH];
                else
                    ;
        for(j = 1 ; j < KERNEL_SIZE * KERNEL_SIZE ; j = j + 1) begin:  feature_in_buf1_i
            always@(posedge clk or negedge rst_n)
                if(!rst_n)
                    feature_in_buf1[i * KERNEL_SIZE * KERNEL_SIZE + j - 1 ] <= 0;
                else
                    if((CLP_type[3] == 1)&& (feature_mem_read_cnt <= feature_amount))
                        feature_in_buf1[i * KERNEL_SIZE * KERNEL_SIZE + j - 1 ] <= feature_in_buf1[i * KERNEL_SIZE * KERNEL_SIZE + j];
                    else
                        ;
        end
    end
endgenerate





generate
for(i = 0 ; i <Tn ; i = i + 1) begin:feature_wire_i
    for(j = 0 ; j < KERNEL_SIZE; j = j + 1) begin:feature_wire_j
        for(k = 0 ; k < KERNEL_SIZE; k = k + 1) begin:feature_wire_k
            assign feature_wire[i * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH + j * KERNEL_SIZE * FEATURE_WIDTH + k * FEATURE_WIDTH + FEATURE_WIDTH - 1 : 
                                i * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH + j * KERNEL_SIZE * FEATURE_WIDTH + k * FEATURE_WIDTH]
                    = (CLP_type[3] == 0) ?  feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE + j * KERNEL_SIZE + k] : feature_in_buf1[i * KERNEL_SIZE * KERNEL_SIZE + j * KERNEL_SIZE + k];
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








reg     [8:0]                                                               weight_mem_addr;
wire    [49:0]                                                              weight_mem_dout;

reg                                                                         weight_mem_read_enable;
reg                                                                         weight_mem_read_enable_p;
reg                                                                         weight_mem_read_enable_p2;

reg     [ KERNEL_SIZE * KERNEL_SIZE * KERNEL_WIDTH - 1 : 0 ]                weight_in_buf[Tn * Tm - 1 : 0];
reg     [8:0]                                                               weight_mem_read_cnt;
wire    [ Tn * Tm * KERNEL_SIZE * KERNEL_SIZE * KERNEL_WIDTH - 1 : 0 ]      weight_wire;
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







reg                 scaler_mem_enable;
reg                 scaler_mem_enable_p;
wire [31:0]         scaler_mem_dout;
reg                 scaler_wire_ready;
reg  [31:0]         scaler_buf;
wire  [31:0]        scaler_wire;

scaler_mem_gen scaler_mem (
  .clka(clk),    // input wire clka
  .ena(scaler_mem_enable),      // input wire ena
  .addra(scaler_mem_addr[3:0]),  // input wire [3 : 0] addra
  .douta(scaler_mem_dout)  // output wire [31 : 0] douta
);


always@(posedge clk or negedge rst_n)
    if(!rst_n)
        scaler_mem_enable_p <= 0;
    else
        scaler_mem_enable_p <= scaler_mem_enable;    

always@(posedge clk or negedge rst_n)
    if(!rst_n)
        begin
            scaler_mem_enable <= 0;
            scaler_wire_ready <= 0;
        end
    else 
        if(state == 0)
            begin
                scaler_mem_enable <= 0;
                scaler_wire_ready <= 0;
            end    
        else    
            if(scaler_wire_ready == 0)
                begin
                    scaler_mem_enable <= 1;
                    scaler_wire_ready <= 1;
                end
            else
                begin
                    scaler_mem_enable <= 0;  
                end     
                

always@(posedge clk or negedge rst_n)
    if(!rst_n)
        scaler_buf <= 0;
    else
        if((scaler_mem_enable_p == 1) && (scaler_mem_enable == 0))
            scaler_buf <= scaler_mem_dout;    
        else
           ;


assign scaler_wire = scaler_buf;



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
