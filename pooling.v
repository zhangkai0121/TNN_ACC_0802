module pooling(
    clk,
    rst_n,
    feature_in,
    feature_out
);
input clk;
input rst_n;
input [16*9-1:0]feature_in;
output[8:0]feature_out;

wire[8:0] comparator_wire[30:0];


assign feature_out = comparator_wire[0];
genvar i;

generate
    for(i=0;i<16;i=i+1)begin:comparator_wire_shift
        assign comparator_wire[i+15] = feature_in[i*9+8:i*9];
    end
endgenerate


generate
    for(i=30;i>=1;i=i-2) begin:comparator_module
        comparator_unit my_comparator(
                           .clk(clk),
                           .rst_n(rst_n),
                           .data_in_a(comparator_wire[i]),
                           .data_in_b(comparator_wire[i-1]),
                           .data_out(comparator_wire[(i/2)-1])
                           );
    
    end
endgenerate

endmodule


module comparator_unit(clk,rst_n,data_in_a,data_in_b,data_out);

input clk;
input rst_n;
input [8:0]data_in_a;
input [8:0]data_in_b;
output reg [8:0]data_out;

always @(posedge clk or negedge rst_n)
    begin
       if(!rst_n)
           data_out <= 9'b0;
       else
           data_out <= (data_in_a >= data_in_b)?data_in_a:data_in_b;
    end
endmodule