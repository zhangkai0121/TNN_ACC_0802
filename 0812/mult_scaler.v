module mult_scaler#(
    parameter FEATURE_WIDTH = 32,
    parameter SCALER_WIDTH = 32
)(
    input wire                                      clk,
    input wire                                      rst_n,
    input wire signed [ FEATURE_WIDTH - 1 : 0 ]     in1,
    input wire signed [ FEATURE_WIDTH - 1 : 0 ]     in2,
    output wire signed [ FEATURE_WIDTH - 1 : 0 ]    out
  );
reg    signed [ FEATURE_WIDTH + SCALER_WIDTH  - 1 :0]   temp_out;

always@(posedge clk or negedge rst_n)
    if(!rst_n)
        temp_out<= 0;
    else
        temp_out <= in1 * in2;

assign out = temp_out>>>16;
//assign out[`MULT_SCALER_OUT_WIDTH - 1 : 0 ] = temp_out[`ADD_OUT_WIDTH + `SCALER_WIDTH  - 1: `ADD_OUT_WIDTH + `SCALER_WIDTH - `MULT_SCALER_OUT_WIDTH ];
endmodule