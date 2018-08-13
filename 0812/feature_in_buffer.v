`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/27/2018 06:57:31 PM
// Design Name: 
// Module Name: feature_in_buffer
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


module feature_in_buffer(
    clk,
    rst_n,
    data_in,
    ctr,
    busy_flag,
    CLP_state,
    CLP_ctr
    );

input clk;
input rst_n;

input [127 : 0] data_in;
input ctr;
output busy_flag;


input CLP_state;
output CLP_ctr;

wire [21:0]     ctr;
reg             busy_flag;


reg [21:0]      ctr_reg;
reg [3:0]       data_in_state;

reg [19:0]      data_amount;  // [19:10] for buffer1    [9:0] for buffer0
reg [13:0]      num_of_use;   // [13:7]  for buffer1    [6:0] for buffer0;
reg [7:0]       CLP_type;     // [7:4]   for buffer1    [3:0] for buffer0;
reg [1:0]       data_valid;   // [1]     for buffer1    [0]   for buffer0;




reg             buffer0_wr_enable;
reg             buffer0_wea;
reg [10 : 0]    buffer0_wr_addr;
reg [127 : 0]   buffer0_wr_data;


reg             buffer0_rd_enable;
reg [10 : 0]    buffer0_rd_addr;
wire [127 : 0]   buffer0_rd_data;

reg             buffer1_wr_enable;
reg             buffer1_wea;
reg [10 : 0]    buffer1_wr_addr;
reg [127 : 0]   buffer1_wr_data;


reg             buffer1_rd_enable;
reg [10 : 0]    buffer1_rd_addr;
wire [127 : 0]   buffer1_rd_data;



always@(posedge clk or negedge rst_n)
    if(!rst_n)
        ctr_reg <= 0;
    else
        if(busy_flag == 0)
            ctr_reg <= ctr;
        else
            ctr_reg <= ctr_reg;

always@(posedge clk or rst_n)
    if(!rst_n)
        begin
            data_in_state <= 0;
            data_amount <= 0;
            num_of_use <= 0;
            data_valid <= 0;
            
            buffer0_wea <= 0;
            buffer0_wr_addr <= 0;
            buffer0_wr_data <= 0;
            buffer0_wr_enable <= 0;
            
            
            buffer1_wea <= 0;
            buffer1_wr_addr <= 0;
            buffer1_wr_data <= 0;
            buffer1_wr_enable <= 0;
            
           
        end
    else 
        begin
            case(data_in_state)
                0:begin    //00
                    if(ctr_reg[21] == 1)    //--->01
                        begin
                            busy_flag <= 1;
                            
                            data_amount[9:0] <= ctr_reg[9:0];
                            num_of_use[6:0]  <= ctr_reg[16:10];
                            CLP_type[3:0]    <= ctr_reg[20:17];   
                            
                            buffer0_wr_enable <= 1;
                            buffer0_wr_data <= data_in;
                            buffer0_wr_addr <= 0;
                            
                            
                            
                            data_in_state    <= 1;
                        end
                    else
                            busy_flag <= 0;  
                  end 
                1:begin     //01
                    if(buffer0_wr_addr == data_amount[9:0]-1)   //--->02
                        begin
                            buffer0_wr_enable <= 0;
                            
                            busy_flag <= 0;
                            ctr_reg <= 0;
                            
                            data_in_state <= 2;
                        end
                    else
                        begin
                            buffer0_wr_addr <= buffer0_wr_addr + 1;
                            buffer0_wr_data <= data_in;
                            data_valid <= 2'b01;
                        end
                 end
                 2:begin    //02
                    if(buffer0_rd_addr == data_amount[9:0]-1)    //--->00
                        begin
                            if( num_of_use[6:0] == 1)
                                begin
                                    data_in_state <= 0;
                                    num_of_use[6:0] <= 0;
                                end
                            else
                                num_of_use[6:0] <= num_of_use[6:0] - 1;
                            
                        end
                    else if(ctr_reg[21] == 1)                   //--->12
                        begin
                            busy_flag <= 1;
                            
                            data_amount[19:10] <= ctr_reg[9:0];
                            num_of_use[13:7]  <= ctr_reg[16:10];
                            CLP_type[7:4]    <= ctr_reg[20:17];   
                            
                            buffer1_wr_enable <= 1;
                            buffer1_wr_data <= data_in;
                            buffer1_wr_addr <= 0;
                            
                            data_in_state    <= 3;
                        end
                    else
                        data_in_state <= data_in_state;
                 end
                 3:begin     //12
                    if(buffer0_rd_addr == data_amount[9:0]-1)    //--->10
                        begin
                            if( num_of_use[6:0] == 1)
                                begin
                                    data_in_state <= 4;
                                    num_of_use[6:0] <= 0;
                                end
                            else
                                num_of_use[6:0] <= num_of_use[6:0] - 1;

                        end
                    else if(buffer1_wr_addr == data_amount[19:10]-1) //--->22
                        begin
                            buffer1_wr_enable <= 0;
                            data_in_state <= 5;
                        end
                    else 
                        begin
                            buffer1_wr_addr <= buffer1_wr_addr + 1;
                            buffer1_wr_data <= data_in;
                        end
                  end
                 4:begin     //10
                    if(buffer1_wr_addr == data_amount[19:10]-1)   //--->20
                        begin
                            buffer1_wr_enable <= 0;
                            
                            ctr_reg <= 0;
                            busy_flag <= 0;
                            
                            data_in_state <= 6;
                        end
                    else
                        begin
                            buffer1_wr_addr <= buffer1_wr_addr + 1;
                            buffer1_wr_data <= data_in;
                        end
                 end
                 5:begin     //22
                    if(buffer0_rd_addr == data_amount[9:0]-1)    //--->20
                        begin
                            if( num_of_use[6:0] == 1)
                                begin
                                    busy_flag <= 0;
                                    ctr_reg <= 0;
                                    data_in_state <= 4;
                                    num_of_use[6:0] <= 0;
                                end
                            else
                                num_of_use[6:0] <= num_of_use[6:0] - 1;
                        end
                    else if(buffer1_rd_addr ==  data_amount[19:10]-1)  //--->02
                        begin                           
                            if( num_of_use[13:7] == 1)
                                begin
                                    busy_flag <= 0;
                                    ctr_reg <= 0;
                                    data_in_state <= 2;
                                    num_of_use[13:7] <= 0;
                                end
                            else
                                num_of_use[13:7] <= num_of_use[13:7] - 1;
                        end
                    else
                        data_in_state <= data_in_state;
                 end
                 6:begin    //20
                    if(ctr_reg[21] == 1)       //--->21
                        begin
                            busy_flag <= 1;
                                                  
                            data_amount[9:0] <= ctr_reg[9:0];
                            num_of_use[6:0]  <= ctr_reg[16:10];
                            CLP_type[3:0]    <= ctr_reg[20:17];   
                          
                            buffer0_wr_enable <= 1;
                            buffer0_wr_data <= data_in;
                            buffer0_wr_addr <= 0;
                        
                            data_in_state <= 7;
                        end
                    else if(buffer1_rd_addr ==  data_amount[19:10]-1)    //--->00
                        begin
                            begin                           
                                if( num_of_use[13:7] == 1)
                                    begin
                                        data_in_state <= 0;
                                        num_of_use[13:7] <= 0;
                                    end
                                else
                                    num_of_use[13:7] <= num_of_use[13:7] - 1;
                            end
                        end
                    else
                        data_in_state <= data_in_state;
                 end
                 7:begin  //21
                    if(buffer1_rd_addr ==  data_amount[19:10]-1)   //--->01
                        begin                                                                  
                            if( num_of_use[13:7] == 1)
                                begin
                                    data_in_state<= 1;
                                    num_of_use[13:7] <= 0;
                                end
                            else
                                num_of_use[13:7] <= num_of_use[13:7] - 1;
                        end                      
                    else if(buffer0_wr_addr == data_amount[9:0]-1)     //--->22
                        begin
                            buffer0_wr_enable <= 0;
                            data_in_state <= 5;
                        end
                    else
                        begin
                            buffer0_wr_addr <= buffer0_wr_addr + 1;
                            buffer0_wr_data <= data_in;
                        end
                 end
            endcase
        end


reg [3:0]       data_out_state;


always@(posedge clk or negedge rst_n)
    if(!rst_n)
        begin
        
        end
    else
        begin
        
        end




feature_in_buffer_gen buffer0 (
  .clka(clk),    // input wire clka
  .ena(buffer0_wr_enable),      // input wire ena
  .wea(buffer0_wea),      // input wire [0 : 0] wea
  .addra(buffer0_wr_addr),  // input wire [10 : 0] addra
  .dina(buffer0_wr_data),    // input wire [127 : 0] dina
  .clkb(clk),    // input wire clkb
  .enb(buffer0_rd_enable),      // input wire enb
  .addrb(buffer0_rd_addr),  // input wire [10 : 0] addrb
  .doutb(buffer0_rd_data)  // output wire [127 : 0] doutb
);

feature_in_buffer_gen buffer1 (
  .clka(clk),    // input wire clka
  .ena(buffer1_wr_enable),      // input wire ena
  .wea(buffer1_wea),      // input wire [0 : 0] wea
  .addra(buffer1_wr_addr),  // input wire [10 : 0] addra
  .dina(buffer1_wr_data),    // input wire [127 : 0] dina
  .clkb(clk),    // input wire clkb
  .enb(buffer1_rd_enable),      // input wire enb
  .addrb(buffer1_rd_addr),  // input wire [10 : 0] addrb
  .doutb(buffer1_rd_data)  // output wire [127 : 0] doutb
);






endmodule
