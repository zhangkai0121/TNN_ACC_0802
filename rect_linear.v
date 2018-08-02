module rect_linear(
     clk,
     rst_n,
     function_in,
     function_out
    );

parameter FEATURE_WIDTH = 32;


input clk;
input rst_n;
input [FEATURE_WIDTH - 1:0]function_in;
output [FEATURE_WIDTH- 1:0]function_out;    
    
reg [FEATURE_WIDTH - 1 :0]function_out;

always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            function_out <= 0;
        else if(function_in[FEATURE_WIDTH- 1] == 1'b1)
            function_out <= 0;
        else 
            function_out <=  function_in;
    end
endmodule