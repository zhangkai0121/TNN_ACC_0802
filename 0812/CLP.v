module CLP#(
    parameter Tn = 4,
    parameter Tm = 8,

    parameter KERNEL_SIZE = 5,
    parameter KERNEL_WIDTH = 2,

    parameter SCALER_WIDTH = 32,

    parameter FEATURE_WIDTH = 32,
    parameter FEATURE_SIZE = 28,

    parameter ADDER_TREE_CELL=63,
    parameter ADDER_TREE_CELL2 = 7,
    
    parameter BIAS_WIDTH = 32,
    parameter COMPARE_TREE_CELL = 7    
)( 
    input   wire                                                                    clk,
    input   wire                                                                    rst_n,
    input   wire  [ Tn * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH - 1 : 0 ]        feature_in,
    input   wire  [ Tn * Tm * KERNEL_SIZE * KERNEL_SIZE * KERNEL_WIDTH - 1 : 0 ]    weight_in,
    input   wire  [ SCALER_WIDTH - 1 : 0 ]                                          weight_scaler,
    input   wire  [ Tm * BIAS_WIDTH - 1 : 0 ]                                       bias_in,
    input   wire  [ 3 : 0 ]                                                         ctr,
    input   wire                                                                    enable,
    input   wire                                                                    addr_clear,
    input   wire  [ 9 : 0 ]                                                         bias_out_feature_size,
    output  wire                                                                    out_valid,
    output  wire  [ Tm * FEATURE_WIDTH - 1 : 0 ]                                    feature_out
    );

wire        [ FEATURE_WIDTH - 1 : 0 ]                                                   feature_in_wire[Tn * KERNEL_SIZE * KERNEL_SIZE - 1:0];
wire        [ KERNEL_WIDTH - 1 : 0 ]                                                    weight_in_wire[Tn * Tm * KERNEL_SIZE * KERNEL_SIZE - 1 : 0];
wire        [ FEATURE_WIDTH - 1 : 0 ]                                                   select_out_wire[Tn * Tm * KERNEL_SIZE * KERNEL_SIZE - 1 : 0];
wire signed [ FEATURE_WIDTH - 1 :0 ]                                                    adder_tree_wire[Tn * Tm * ADDER_TREE_CELL - 1 : 0];
wire signed [ FEATURE_WIDTH - 1 : 0 ]                                                   scaler_out[Tm - 1 : 0];
wire signed [ FEATURE_WIDTH - 1 : 0 ]                                                   adder_tree_wire2[Tm * ADDER_TREE_CELL2 - 1 : 0];
wire signed [ FEATURE_WIDTH - 1 : 0 ]                                                   bias_out[Tm - 1 : 0];
wire                                                                                    pooling_enable;
reg                                                                                     pooling_enable_p;
wire signed [ FEATURE_WIDTH - 1 : 0 ]                                                   compare_tree_wire[Tm * COMPARE_TREE_CELL - 1 : 0];
wire signed [ FEATURE_WIDTH - 1 : 0 ]                                                   function_in[Tm - 1 : 0];
wire signed [ FEATURE_WIDTH - 1 : 0 ]                                                   function_out[Tm - 1 : 0]; 
reg signed [ FEATURE_WIDTH - 1 : 0 ]                                                    accumulate_out[Tm - 1 : 0]; 

genvar i,j,k,x,y,z;

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
//             add_unit my_adder_tree2(
//                               .clk(clk),
//                               .rst_n(rst_n),
//                               .adder_a(adder_tree_wire2[ i * ADDER_TREE_CELL2  + (j - 1)]),
//                               .adder_b(adder_tree_wire2[ i * ADDER_TREE_CELL2 + j]),
//                               .adder_out(adder_tree_wire2[ i * ADDER_TREE_CELL2  + ( j / 2 ) - 1])
//                             );
                add_unit_by_DSP my_adder_tree2 (
                  .A(adder_tree_wire2[ i * ADDER_TREE_CELL2  + (j - 1)]),      // input wire [31 : 0] A
                  .B(adder_tree_wire2[ i * ADDER_TREE_CELL2 + j]),      // input wire [31 : 0] B
                  .CLK(clk),  // input wire CLK
                  .CE(1),    // input wire CE
                  .S(adder_tree_wire2[ i * ADDER_TREE_CELL2  + ( j / 2 ) - 1])      // output wire [31 : 0] S
                );

        end
    end
endgenerate

generate
    for(i = 0; i < Tm;i = i + 1) begin:add_bias_i
//            add_unit bias_add(
//                                .clk(clk),
//                                .rst_n(rst_n),
//                                .adder_a(adder_tree_wire2[i * ADDER_TREE_CELL2]),
//                                .adder_b(bias_in[i * BIAS_WIDTH + BIAS_WIDTH - 1 : i * BIAS_WIDTH]),
//                                .adder_out(bias_out[i])
//                            );
                            
                            
            add_unit_by_DSP bias_add (
              .A(adder_tree_wire2[i * ADDER_TREE_CELL2]),      // input wire [31 : 0] A
              .B(bias_in[i * BIAS_WIDTH + BIAS_WIDTH - 1 : i * BIAS_WIDTH]),      // input wire [31 : 0] B
              .CLK(clk),  // input wire CLK
              .CE(1),    // input wire CE
              .S(bias_out[i])      // output wire [31 : 0] S
            );                
                            
                            
    end
endgenerate

generate 
    for(i = 0; i < Tm;i = i + 1) begin:mult_i
            mult_scaler my_mult_scaler(
                                        .clk(clk),
                                        .rst_n(rst_n),
                                        .in1(bias_out[i]),
                                        .in2(weight_scaler),
                                        .out(scaler_out[i])
                                        );
    end
endgenerate





generate
    for(i = 0 ; i < Tm ; i = i + 1) begin:rect_linear_i
        rect_linear ReLu(
            .clk(clk),
            .rst_n(rst_n),
            .function_in(function_in[i]),
            .function_out(function_out[i])
            );
    end
endgenerate




wire        [ 3 : 0 ]                                                                   ctr_p;
wire                                                                                    out_valid_scaler_out;
wire                                                                                    out_valid_function_out;
wire                                                                                    pooling_enable_scaler_out;
wire                                                                                    pooling_enable_function_out;
wire                                                                                    pooling_enable_storage_function_out;


reg                                                                                     addr_clear_p;

reg signed  [FEATURE_WIDTH - 1 : 0 ]                                                    pooling_in[Tm - 1 : 0];
reg signed  [FEATURE_WIDTH - 1 : 0 ]                                                    IP_output[Tm - 1 : 0];
reg signed  [FEATURE_WIDTH - 1 : 0 ]                                                    IP_temp_result[Tm - 1 : 0];
wire                                                                                    result_read_enable_for_IP;

reg     [ Tm * FEATURE_WIDTH - 1 : 0 ]              temp_result_mem_write_data;
reg     [ 9 : 0 ]                                   temp_result_mem_write_addr;
wire                                                temp_result_mem_write_enable_ctr;
wire                                                temp_result_mem_write_enable_ctr2;
wire                                                temp_result_mem_write_enable;

wire    [ Tm * FEATURE_WIDTH - 1 : 0 ]              temp_result_mem_read_data;
reg     [ 9 : 0 ]                                   temp_result_mem_read_addr;
wire                                                temp_result_mem_read_enable_ctr;
wire                                                temp_result_mem_read_enable;

generate
    for(i = 0; i < Tm;i = i + 1) begin:function_in_wire_i
        assign function_in[i] = ((ctr_p == 4'b0010) || (ctr_p == 4'b1000)) ? scaler_out[i] : accumulate_out[i];
    end
endgenerate


register #(
     .NUM_STAGES(11),
     .DATA_WIDTH(4)
     )ctr_delay(
     .CLK(clk),
     .RESET(rst_n),
     .DIN(ctr),
     .DOUT(ctr_p)           
     );
register #(
     .NUM_STAGES(10),
     .DATA_WIDTH(1)
     )enable_delay_scaler_out(
     .CLK(clk),
     .RESET(rst_n),
     .DIN(enable),
     .DOUT(out_valid_scaler_out)           
     );

register #(
     .NUM_STAGES(11),
     .DATA_WIDTH(1)
     )enable_delay_function_out(
     .CLK(clk),
     .RESET(rst_n),
     .DIN(enable),
     .DOUT(out_valid_function_out)           
     );

register #(
  .NUM_STAGES(11),
  .DATA_WIDTH(1)
  )enable_delay_pooling_scaler_out(
  .CLK(clk),
  .RESET(rst_n),
  .DIN(enable),
  .DOUT(pooling_enable_scaler_out)           
  );

register #(
  .NUM_STAGES(12),
  .DATA_WIDTH(1)
  )enable_delay_pooling_function_out(
  .CLK(clk),
  .RESET(rst_n),
  .DIN(enable),
  .DOUT(pooling_enable_function_out)           
  );
register #(
    .NUM_STAGES(13),
    .DATA_WIDTH(1)
    )enable_delay_pooling_storage_function_out(
    .CLK(clk),
    .RESET(rst_n),
    .DIN(enable),
    .DOUT(pooling_enable_storage_function_out)           
    );
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
     .NUM_STAGES(9),
     .DATA_WIDTH(1)
     )temp_result_mem_read_enable_delay(
     .CLK(clk),
     .RESET(rst_n),
     .DIN(enable),
     .DOUT(temp_result_mem_read_enable_ctr)           
     );


assign pooling_enable = (ctr_p == 4'b0001) ? pooling_enable_scaler_out : 
                        ((ctr_p == 4'b0010) ? pooling_enable_function_out :
                        ((ctr_p == 4'b0110) ? pooling_enable_storage_function_out : 1'dz));


generate
    for(i = 0 ; i < Tm; i = i + 1) begin:ctr_i
        always@(posedge clk or negedge rst_n)
            if(!rst_n)
                ;
            else
                case(ctr_p)
                    4'b0001:begin
                        pooling_in[i] <= scaler_out[i];
                    end
                    4'b0010:begin
                        pooling_in[i] <= function_out[i];
                    end
                    4'b0011:begin
                        temp_result_mem_write_data[ i * FEATURE_WIDTH + FEATURE_WIDTH - 1 : i * FEATURE_WIDTH ] <= scaler_out[i];
                    end
                    4'b0100:begin
                        temp_result_mem_write_data[ i * FEATURE_WIDTH + FEATURE_WIDTH - 1 : i * FEATURE_WIDTH ] <= scaler_out[i] + temp_result_mem_read_data[ i * FEATURE_WIDTH + FEATURE_WIDTH - 1 : i * FEATURE_WIDTH ];
                    end
//                    4'b0101:
                    4'b0110:begin
                        accumulate_out[i] <= scaler_out[i] + temp_result_mem_read_data[ i * FEATURE_WIDTH + FEATURE_WIDTH - 1 : i * FEATURE_WIDTH ];
                        pooling_in[i] <= function_out[i];
                    end
                    4'b0111:begin
                        ;
                    end
                    4'b1000:begin
                        ;
                    end
//                    4'b1001:
//                    4'b1010:
                
                
                
                
                
//                    4'b0000:begin
//                        pooling_in[i] <= scaler_out[i];  
//                    end
//                    4'b0001:begin
//                        temp_result_mem_write_data[ i * FEATURE_WIDTH + FEATURE_WIDTH - 1 : i * FEATURE_WIDTH ] <= scaler_out[i];
//                    end
//                    4'b0010:begin
//                        temp_result_mem_write_data[ i * FEATURE_WIDTH + FEATURE_WIDTH - 1 : i * FEATURE_WIDTH ] <= scaler_out[i] + temp_result_mem_read_data[ i * FEATURE_WIDTH + FEATURE_WIDTH - 1 : i * FEATURE_WIDTH ];
//                    end
//                    4'b0011:begin
//                        pooling_in[i] <= scaler_out[i] + temp_result_mem_read_data[ i * FEATURE_WIDTH + FEATURE_WIDTH - 1 : i * FEATURE_WIDTH ];
//                    end
//                    4'b1000:begin
//                        if(enable == 1)
//                            IP_output[i] <= scaler_out[i];
//                    end
//                    4'b1001:begin
//                        if(enable == 1)
//                            IP_temp_result[i] <= scaler_out[i];
//                    end
//                    4'b1010:begin
//                        if(enable == 1)
//                            IP_temp_result[i] <= scaler_out[i] + IP_temp_result[i];
//                    end
//                    4'b1011:begin
//                        if(enable == 1)
//                            IP_output[i] <= scaler_out[i] + IP_temp_result[i];
//                    end
                endcase                   
    end
endgenerate

//register #(
//     .NUM_STAGES(1),
//     .DATA_WIDTH(1)
//     )IP_reault_read_enable_delay(
//     .CLK(clk),
//     .RESET(rst_n),
//     .DIN(enable),
//     .DOUT(result_read_enable_for_IP)           
//     );
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


assign temp_result_mem_write_enable = temp_result_mem_write_enable_ctr && ((ctr_p == 4'b0011)||(ctr_p == 4'b0100));
assign temp_result_mem_read_enable = temp_result_mem_read_enable_ctr && ((ctr_p == 4'b0100)||(ctr_p == 4'b0110));


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


reg [ FEATURE_WIDTH - 1 : 0 ]   pooling_temp_3[Tm - 1 : 0];
reg [ FEATURE_WIDTH - 1 : 0 ]   pooling_temp1[Tm - 1 : 0];
reg [ FEATURE_WIDTH - 1 : 0 ]   pooling_temp2[Tm - 1 : 0];
reg [ FEATURE_WIDTH - 1 : 0 ]   pooling_temp3[Tm - 1 : 0];
reg [ FEATURE_WIDTH - 1 : 0 ]   pooling_temp4[Tm - 1 : 0];
wire                            pooling_data_ready;
wire[ FEATURE_WIDTH - 1 : 0 ]   pooling_out[Tm - 1 : 0];


wire                                pooling_buf_wr_en;
wire                                pooling_buf_rd_en;
wire[ FEATURE_WIDTH * 2 - 1 : 0 ]   pooling_buf_dout[Tm - 1 : 0];
reg                                 pooling_buf_wr_ctr;
wire                                pooling_process_enable;
reg                                 pooling_process_ctr;


generate
    for(i = 0 ; i < Tm ; i = i + 1 ) begin:pooling_buf_i
        pooling_buf_by_fifo_gen pooling_buf (
          .clk(clk),      // input wire clk
          .din(pooling_in[i]),      // input wire [31 : 0] din
          .wr_en(pooling_buf_wr_en),  // input wire wr_en
          .rd_en(pooling_buf_rd_en),  // input wire rd_en
          .dout(pooling_buf_dout[i]),    // output wire [31 : 0] dout
          .full(),    // output wire full
          .empty()  // output wire empty
        ); 
    end
endgenerate

always@(posedge clk or negedge rst_n)
    if(!rst_n)
        pooling_enable_p <= 0;
    else
        pooling_enable_p <= pooling_enable;   
        
always@(posedge clk or negedge rst_n)
    if(!rst_n)
        pooling_buf_wr_ctr <= 0;
    else
        if((pooling_enable == 0) && (pooling_enable_p == 1))
            pooling_buf_wr_ctr <= 1 - pooling_buf_wr_ctr;    
            
assign  pooling_buf_wr_en = (pooling_buf_wr_ctr == 0)? pooling_enable : 1'd0;
assign  pooling_process_enable = (pooling_buf_wr_ctr == 1) ? pooling_enable : 1'd0;
assign  pooling_buf_rd_en = (pooling_process_enable == 1) && (pooling_process_ctr == 0);
always@(posedge clk or negedge rst_n)
    if(!rst_n)
        pooling_process_ctr <= 0;
    else
        if(pooling_process_enable)
            pooling_process_ctr <= 1-pooling_process_ctr;
        else
            pooling_process_ctr <= pooling_process_ctr;       

generate
    for(i = 0 ; i < Tm ; i = i + 1) begin:pooling_process_i
        always@(posedge clk or negedge rst_n)
            if(!rst_n)
                begin
                    pooling_temp_3[i] <= 0;
                    pooling_temp1[i] <= 0;
                    pooling_temp2[i] <= 0;
                    pooling_temp3[i] <= 0;
                    pooling_temp4[i] <= 0;
                end
            else 
                begin
                    if((pooling_process_enable == 1) &&(pooling_process_ctr == 0))
                        begin
                            pooling_temp_3[i] <= pooling_in[i];
                        end
                    else if((pooling_process_enable == 1) &&(pooling_process_ctr == 1))
                        begin
                            {pooling_temp1[i],pooling_temp2[i]} <= pooling_buf_dout[i];
                            pooling_temp3[i] <=  pooling_temp_3[i];
                            pooling_temp4[i] <= pooling_in[i];
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
    for(i = 0; i < Tm; i = i + 1) begin:pooling_out_wire_i
        assign pooling_out[i] = compare_tree_wire[i * COMPARE_TREE_CELL];
    end
endgenerate

register #(
     .NUM_STAGES(3),
     .DATA_WIDTH(1)
     )data_ready_delay(
     .CLK(clk),
     .RESET(rst_n),
     .DIN(pooling_process_ctr),
     .DOUT(pooling_data_ready)           
     );
//assign out_valid = (ctr_p[3] == 0) ?pooling_data_ready :(result_read_enable_for_IP&&((ctr_p[2:0]==3'b000)||(ctr_p[2:0]==3'b011))) ;

generate
    for(i = 0 ; i < Tm ; i = i + 1) begin:feature_out_i
//        assign feature_out[i * FEATURE_WIDTH + FEATURE_WIDTH - 1 : i * FEATURE_WIDTH] = (ctr_p[3] == 0) ?pooling_out[i]:
//                                                                                                        IP_output[i];
         assign feature_out[i * FEATURE_WIDTH + FEATURE_WIDTH - 1 : i * FEATURE_WIDTH] =  ((ctr_p == 4'b0001) ||(ctr_p == 4'b0010) || (ctr_p == 4'b0110)) ? pooling_out[i] :
                                                                                         ((ctr_p==4'b0111) ? scaler_out[i]:
                                                                                         ((ctr_p==4'b1000) ? function_out[i]:32'dz));
    end
endgenerate

assign out_valid = ((ctr_p == 4'b0001) ||(ctr_p == 4'b0010)||(ctr_p == 4'b0110)) ? pooling_data_ready :
                   ( (ctr_p==4'b0111) ? out_valid_scaler_out :
                   ((ctr_p==4'b1000) ? out_valid_function_out:1'dz)) ;

endmodule