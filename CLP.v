module CLP( 
    clk,
    rst_n,
    feature_in,
    weight_in,
    weight_scaler,
    bias_in,
    ctr,
    enable,
    addr_clear,
    bias_out_feature_size,
    out_valid,
    feature_out
    );

parameter Tn = 4;
parameter Tm = 8;

parameter KERNEL_SIZE = 5;
parameter KERNEL_WIDTH = 2;

parameter SCALER_WIDTH = 32;


parameter FEATURE_WIDTH = 32;
parameter FEATURE_SIZE = 28;

parameter ADDER_TREE_CELL=63;
parameter ADDER_TREE_CELL2 = 7;


parameter BIAS_WIDTH = 32;
parameter MAX_BIAS_OUT_SIZE = 100;
parameter COMPARE_TREE_CELL = 7;




input clk;
input rst_n;
input feature_in;
input weight_in;
input bias_in;
input weight_scaler;
input ctr;
input enable;
input addr_clear;
input bias_out_feature_size;
output out_valid;
output feature_out;


wire        [ Tn * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH - 1 : 0 ]                  feature_in;
wire        [ Tn * Tm * KERNEL_SIZE * KERNEL_SIZE * KERNEL_WIDTH - 1 : 0 ]              weight_in;
wire        [ SCALER_WIDTH - 1 : 0 ]                                                    weight_scaler;
wire        [ Tm * BIAS_WIDTH - 1 : 0 ]                                                 bias_in;
wire        [ 9 : 0 ]                                                                   bias_out_feature_size;
wire        [ 3 : 0 ]                                                                   ctr;
wire        [ Tm * FEATURE_WIDTH - 1 : 0 ]                                              feature_out;



wire        [ FEATURE_WIDTH - 1 : 0 ]                                                   feature_in_wire[Tn * KERNEL_SIZE * KERNEL_SIZE - 1:0];
wire        [ KERNEL_WIDTH - 1 : 0 ]                                                    weight_in_wire[Tn * Tm * KERNEL_SIZE * KERNEL_SIZE - 1 : 0];
wire        [ FEATURE_WIDTH - 1 : 0 ]                                                   select_out_wire[Tn * Tm * KERNEL_SIZE * KERNEL_SIZE - 1 : 0];
wire signed [ FEATURE_WIDTH - 1 :0 ]                                                    adder_tree_wire[Tn * Tm * ADDER_TREE_CELL - 1 : 0];
wire signed [ FEATURE_WIDTH - 1 : 0 ]                                                   scaler_out[Tm - 1 : 0];
wire signed [ FEATURE_WIDTH - 1 : 0 ]                                                   adder_tree_wire2[Tm * ADDER_TREE_CELL2 - 1 : 0];
wire signed [ FEATURE_WIDTH - 1 : 0 ]                                                   bias_out[Tm - 1 : 0];
reg  signed [ FEATURE_WIDTH - 1 : 0 ]                                                   pooling_buf[Tm * MAX_BIAS_OUT_SIZE - 1 : 0];
wire                                                                                    pooling_enable;
wire signed [ FEATURE_WIDTH - 1 : 0 ]                                                   compare_tree_wire[Tm * COMPARE_TREE_CELL - 1 : 0];


genvar i;
genvar j;
genvar k;
genvar x;
genvar y;
genvar z;


generate
    for(i = 0 ; i < Tn ; i = i + 1) begin:feature_in_wire_i
        for(j = 0 ; j < KERNEL_SIZE ; j = j + 1) begin:feature_in_wire_j
            for(k = 0 ; k < KERNEL_SIZE; k = k + 1) begin:feature_in_wire_k
                assign feature_in_wire[i * KERNEL_SIZE * KERNEL_SIZE + j * KERNEL_SIZE + k] 
                        = feature_in[i * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH + j * KERNEL_SIZE * FEATURE_WIDTH + k * FEATURE_WIDTH  + FEATURE_WIDTH - 1 :
                                     i * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH + j * KERNEL_SIZE * FEATURE_WIDTH + k * FEATURE_WIDTH  ];
            end
        end
    end
endgenerate


generate
    for(i = 0 ; i < Tm;i = i + 1) begin:weight_in_wire_i
        for(j = 0 ; j < Tn; j = j + 1) begin:weight_in_wire_j
            for(k = 0 ; k < KERNEL_SIZE ; k = k + 1) begin:weight_in_wire_k
                for(x = 0 ; x < KERNEL_SIZE ; x = x+ 1) begin:weight_in_wire_x
                    assign weight_in_wire[i * Tn * KERNEL_SIZE * KERNEL_SIZE + j * KERNEL_SIZE * KERNEL_SIZE + k * KERNEL_SIZE + x]
                            = weight_in[i * Tn * KERNEL_SIZE * KERNEL_SIZE * KERNEL_WIDTH + j * KERNEL_SIZE * KERNEL_SIZE * KERNEL_WIDTH + k * KERNEL_SIZE * KERNEL_WIDTH + x * KERNEL_WIDTH + KERNEL_WIDTH - 1 :
                                        i * Tn * KERNEL_SIZE * KERNEL_SIZE * KERNEL_WIDTH + j * KERNEL_SIZE * KERNEL_SIZE * KERNEL_WIDTH + k * KERNEL_SIZE * KERNEL_WIDTH + x * KERNEL_WIDTH];
                end
            end
        end
    end
endgenerate


generate 
    for(x = 0; x < Tm;x = x + 1) begin:select_m
        for(k = 0; k < Tn; k = k + 1) begin:select_n
            for(i = 0; i < KERNEL_SIZE; i = i + 1) begin:select_r
               for(j = 0; j < KERNEL_SIZE; j = j + 1) begin:select_c
                   select_unit my_select_unit(
                                        .clk(clk),
                                        .rst_n(rst_n),
                                        .select_in(feature_in_wire[k * KERNEL_SIZE * KERNEL_SIZE + i * KERNEL_SIZE + j]),
                                        .kernel(weight_in_wire[x * Tn *KERNEL_SIZE *KERNEL_SIZE + k * KERNEL_SIZE * KERNEL_SIZE + i * KERNEL_SIZE + j]),                                
                                        .select_out(select_out_wire[x * Tn * KERNEL_SIZE * KERNEL_SIZE + k * KERNEL_SIZE * KERNEL_SIZE + i * KERNEL_SIZE + j])
                                        );
                end
            end
        end
    end
endgenerate 



generate
    for(x = 0; x < Tm;x = x + 1) begin:adder_tree_wire_m
        for(k = 0; k < Tn; k = k + 1) begin:adder_tree_wire_n
            for(z = (ADDER_TREE_CELL - 1)/2 + KERNEL_SIZE * KERNEL_SIZE ; z < ADDER_TREE_CELL;z = z + 1) begin:adder_tree_wire_z
                assign adder_tree_wire[x * Tn * ADDER_TREE_CELL + k *ADDER_TREE_CELL + z] = 0;
            end
            for (i = 0; i < KERNEL_SIZE; i = i + 1) begin:adder_tree_i
                for(j = 0;j < KERNEL_SIZE;j = j + 1) begin:adder_tree_j
                   assign adder_tree_wire[x * Tn * ADDER_TREE_CELL + k * ADDER_TREE_CELL + i * KERNEL_SIZE + j + (ADDER_TREE_CELL - 1)/2 ]
                              =select_out_wire[x * Tn * KERNEL_SIZE * KERNEL_SIZE + k * KERNEL_SIZE * KERNEL_SIZE   + i * KERNEL_SIZE + j];
                end
            end
        end
    end
endgenerate


generate 
    for(x = 0; x < Tm;x = x + 1) begin:add_m
        for(k = 0; k < Tn; k = k + 1) begin:add_n
            for(i =ADDER_TREE_CELL - 1; i >= 1;i = i - 2) begin:add_i
                      add_unit my_adder_tree(
                        .clk(clk),
                        .rst_n(rst_n),
                        .adder_a(adder_tree_wire[x * Tn * ADDER_TREE_CELL  + k * ADDER_TREE_CELL  + (i - 1)]),
                        .adder_b(adder_tree_wire[x * Tn * ADDER_TREE_CELL  + k * ADDER_TREE_CELL  + i]),
                        .adder_out(adder_tree_wire[x * Tn * ADDER_TREE_CELL + k * ADDER_TREE_CELL  + (i/2) -1])
                      );
            end
        end
    end
endgenerate


generate
    for(i = 0 ; i < Tm ; i = i + 1) begin:adder_tree_wire2_i
        for(j = 0 ; j < Tn ; j = j + 1) begin:adder_tree_wire2_j
            assign adder_tree_wire2[ i * ADDER_TREE_CELL2 + j + ( ADDER_TREE_CELL2 - 1 ) / 2 ] = adder_tree_wire[i * Tn * ADDER_TREE_CELL + j * ADDER_TREE_CELL];
        end
    end
endgenerate

generate
    for(i = 0 ; i < Tm ; i = i + 1) begin:add_2_i
        for(j = ADDER_TREE_CELL2 - 1 ; j >= 1;j = j - 2) begin:add2_j
             add_unit my_adder_tree2(
                               .clk(clk),
                               .rst_n(rst_n),
                               .adder_a(adder_tree_wire2[ i * ADDER_TREE_CELL2  + (j - 1)]),
                               .adder_b(adder_tree_wire2[ i * ADDER_TREE_CELL2 + j]),
                               .adder_out(adder_tree_wire2[ i * ADDER_TREE_CELL2  + ( j / 2 ) - 1])
                             );
        end
    end
endgenerate

generate 
    for(i = 0; i < Tm;i = i + 1) begin:mult_i
            mult_scaler my_mult_scaler(
                                        .clk(clk),
                                        .rst_n(rst_n),
                                        .in1(adder_tree_wire2[i * ADDER_TREE_CELL2]),
                                        .in2(weight_scaler),
                                        .out(scaler_out[i])
                                        );
    end
endgenerate


generate
    for(i = 0; i < Tm;i = i + 1) begin:add_bias_i
            add_unit bias_add(
                                .clk(clk),
                                .rst_n(rst_n),
                                .adder_a(scaler_out[i]),
                                .adder_b(bias_in[i * BIAS_WIDTH + BIAS_WIDTH - 1 : i * BIAS_WIDTH]),
                                .adder_out(bias_out[i])
                            );
    end
endgenerate






reg                                                                                     addr_clear_p;
wire        [ 3 : 0 ]                                                                   ctr_p;
reg signed  [FEATURE_WIDTH - 1 : 0 ]                                                    pooling_in[Tm - 1 : 0];
reg signed  [FEATURE_WIDTH - 1 : 0 ]                                                    temp_result[Tm - 1 : 0];


reg     [ Tm * FEATURE_WIDTH - 1 : 0 ]              temp_result_mem_write_data;
reg     [ 9 : 0 ]                                   temp_result_mem_write_addr;
wire                                                temp_result_mem_write_enable_ctr;
wire                                                temp_result_mem_write_enable_ctr2;
wire                                                temp_result_mem_write_enable;

wire    [ Tm * FEATURE_WIDTH - 1 : 0 ]              temp_result_mem_read_data;
reg     [ 9 : 0 ]                                   temp_result_mem_read_addr;
wire                                                temp_result_mem_read_enable_ctr;
wire                                                temp_result_mem_read_enable;




register #(
     .NUM_STAGES(9),
     .DATA_WIDTH(4)
     )ctr_delay(
     .CLK(clk),
     .RESET(rst_n),
     .DIN(ctr),
     .DOUT(ctr_p)           
     );







generate
    for(i = 0 ; i < Tm; i = i + 1) begin:ctr_i
        always@(posedge clk or negedge rst_n)
            if(!rst_n)
                ;
            else
                case(ctr_p)
                    4'b0000:begin
                        pooling_in[i] <= bias_out[i];  
                    end
                    4'b0001:begin
                        temp_result_mem_write_data[ i * FEATURE_WIDTH + FEATURE_WIDTH - 1 : i * FEATURE_WIDTH ] <= bias_out[i];
                    end
                    4'b0010:begin
                        temp_result_mem_write_data[ i * FEATURE_WIDTH + FEATURE_WIDTH - 1 : i * FEATURE_WIDTH ] <= bias_out[i] + temp_result_mem_read_data[ i * FEATURE_WIDTH + FEATURE_WIDTH - 1 : i * FEATURE_WIDTH ];
                    end
                    4'b0011:begin
                        pooling_in[i] <= bias_out[i] + temp_result_mem_read_data[ i * FEATURE_WIDTH + FEATURE_WIDTH - 1 : i * FEATURE_WIDTH ];
                    end
                endcase                   
    end
endgenerate


register #(
     .NUM_STAGES(11),
     .DATA_WIDTH(1)
     )temp_result_mem_write_enable_delay(
     .CLK(clk),
     .RESET(rst_n),
     .DIN(enable),
     .DOUT(temp_result_mem_write_enable_ctr)           
     );

register #(
     .NUM_STAGES(11),
     .DATA_WIDTH(1)
     )temp_result_mem_write_enable_delay2(
     .CLK(clk),
     .RESET(rst_n),
     .DIN(enable),
     .DOUT(temp_result_mem_write_enable_ctr2)           
     );


register #(
     .NUM_STAGES(9),
     .DATA_WIDTH(1)
     )temp_result_mem_read_enable_delay(
     .CLK(clk),
     .RESET(rst_n),
     .DIN(enable),
     .DOUT(temp_result_mem_read_enable_ctr)           
     );




always@(posedge clk or negedge rst_n)
    if(!rst_n)
        temp_result_mem_write_addr <= 0;
    else
        if((addr_clear == 1) && (addr_clear_p == 0))
            temp_result_mem_write_addr <= 0;   
        else
            if(temp_result_mem_write_enable)
                temp_result_mem_write_addr <= temp_result_mem_write_addr + 1;
            else
                temp_result_mem_write_addr <= temp_result_mem_write_addr;    

always@(posedge clk or negedge rst_n)
    if(!rst_n)
        temp_result_mem_read_addr <= 0;
    else
        if((addr_clear == 1) && (addr_clear_p == 0))
            temp_result_mem_read_addr <= 0;    
        else
            if(temp_result_mem_read_enable)
                temp_result_mem_read_addr <= temp_result_mem_read_addr + 1;
            else 
                temp_result_mem_read_addr <= temp_result_mem_read_addr;    



always@(posedge clk or negedge rst_n)
    if(!rst_n)
        addr_clear_p <= 0;
    else 
        addr_clear_p <= addr_clear;



//assign temp_result_mem_write_enable = (ctr_p == 4'b0001) ? temp_result_mem_write_enable_ctr : ( (ctr_p == 4'b0010) ? temp_result_mem_write_enable_ctr2 : 1'bz);

//assign temp_result_mem_write_enable = temp_result_mem_write_enable_ctr2 &&(ctr_p == 4'b0010);
assign temp_result_mem_write_enable = temp_result_mem_write_enable_ctr &&(ctr_p == 4'b0001 || ctr_p == 4'b0010);
assign temp_result_mem_read_enable = temp_result_mem_read_enable_ctr &&(ctr_p == 4'b0010 || ctr_p == 4'b0011);


temp_result_mem_gen temp_result_mem (
  .clka(clk),    // input wire clka
  .ena(temp_result_mem_write_enable),      // input wire ena
  .wea(1),      // input wire [0 : 0] wea
  .addra(temp_result_mem_write_addr),  // input wire [9 : 0] addra
  .dina(temp_result_mem_write_data),    // input wire [255 : 0] dina
  .clkb(clk),    // input wire clkb
  .enb(temp_result_mem_read_enable),      // input wire enb
  .addrb(temp_result_mem_read_addr),  // input wire [9 : 0] addrb
  .doutb(temp_result_mem_read_data)  // output wire [255 : 0] doutb
);







reg [9:0]                       pooling_cnt1;
reg [9:0]                       pooling_cnt2;
reg [9:0]                       pooling_cnt3;
reg [9:0]                       pooling_buf_addr;
reg [ FEATURE_WIDTH - 1 : 0 ]   pooling_temp_1[Tm - 1 : 0];
reg [ FEATURE_WIDTH - 1 : 0 ]   pooling_temp_3[Tm - 1 : 0];
reg [ FEATURE_WIDTH - 1 : 0 ]   pooling_temp1[Tm - 1 : 0];
reg [ FEATURE_WIDTH - 1 : 0 ]   pooling_temp2[Tm - 1 : 0];
reg [ FEATURE_WIDTH - 1 : 0 ]   pooling_temp3[Tm - 1 : 0];
reg [ FEATURE_WIDTH - 1 : 0 ]   pooling_temp4[Tm - 1 : 0];
wire                            pooling_data_ready;

register #(
     .NUM_STAGES(11),
     .DATA_WIDTH(1)
     )enable_delay(
     .CLK(clk),
     .RESET(rst_n),
     .DIN(enable),
     .DOUT(pooling_enable)           
     );



generate
    for(i = 0 ; i < Tm; i = i + 1) begin:pooling_buf_i
        always@(posedge clk or negedge rst_n)
            if(!rst_n)
                begin
                    pooling_cnt1 <= 0;
                    pooling_cnt2 <= 0;
                    pooling_cnt3 <= 0;
                    pooling_buf_addr <= 0;
                end
            else
                begin
                    if(pooling_enable)
                        begin
                            if(pooling_cnt1 == bias_out_feature_size)
                                begin
                                    pooling_buf_addr <= 0;
                                    if(pooling_cnt3 == bias_out_feature_size - 1)
                                        begin
                                            pooling_cnt3 <= 0;
                                            pooling_cnt1 <= 0;
                                            pooling_cnt2 <= 0;
                                        end
                                    else   
                                        pooling_cnt3 <= pooling_cnt3 + 1;
                                        

                                
                                    if(pooling_cnt2 == 1)
                                        begin
                                            pooling_cnt2 <= 0;
                                            pooling_temp4[i] <= pooling_in[i];
                                            pooling_temp2[i] <=  pooling_buf[i * MAX_BIAS_OUT_SIZE + pooling_cnt3];
                                        end
                                    else
                                        begin
                                            pooling_cnt2 <= pooling_cnt2 + 1;
                                            pooling_temp_3[i] <= pooling_in[i];
                                            pooling_temp_1[i] <=  pooling_buf[i * MAX_BIAS_OUT_SIZE + pooling_cnt3];
                                        end
                                   pooling_temp1[i] <= pooling_temp_1[i];
                                   pooling_temp3[i] <= pooling_temp_3[i];
                                end
                            else
                                begin
                                    pooling_buf[i * MAX_BIAS_OUT_SIZE + pooling_buf_addr] <= pooling_in[i];
                                    pooling_buf_addr <= pooling_buf_addr + 1;
                                    pooling_cnt1 <= pooling_cnt1 + 1;
                                end
                        end
                    else 
                        begin
                            ;
                        end
                end
    end
endgenerate

generate
    for(i = 0 ; i < Tm; i = i + 1) begin:compare_tree_wire_i
        assign compare_tree_wire[i * COMPARE_TREE_CELL + 3] = pooling_temp1[i]; 
        assign compare_tree_wire[i * COMPARE_TREE_CELL + 4] = pooling_temp2[i]; 
        assign compare_tree_wire[i * COMPARE_TREE_CELL + 5] = pooling_temp3[i];
        assign compare_tree_wire[i * COMPARE_TREE_CELL + 6] = pooling_temp4[i];
    end
endgenerate

generate
    for(i = 0 ; i < Tm ; i = i + 1) begin:compare_tree_i
        for(j = COMPARE_TREE_CELL - 1 ; j >= 1;j = j - 2) begin:compare_tree_j
            comparator_unit comparator_tree(
                .clk(clk),
                .rst_n(rst_n),
                .data_in_a(compare_tree_wire[i * COMPARE_TREE_CELL  + (j - 1)]),
                .data_in_b(compare_tree_wire[i * COMPARE_TREE_CELL  + j]),
                .data_out(compare_tree_wire[i * COMPARE_TREE_CELL  + ( j / 2 ) - 1])
            );
        end
    end
endgenerate




generate
    for(i = 0 ; i < Tm ; i = i + 1) begin:feature_out_i
        assign feature_out[i * FEATURE_WIDTH + FEATURE_WIDTH - 1 : i * FEATURE_WIDTH] = compare_tree_wire[i * COMPARE_TREE_CELL];
    end
endgenerate



register #(
     .NUM_STAGES(3),
     .DATA_WIDTH(1)
     )data_ready_delay(
     .CLK(clk),
     .RESET(rst_n),
     .DIN(pooling_cnt3[0]),
     .DOUT(pooling_data_ready)           
     );

assign out_valid = pooling_data_ready;

endmodule