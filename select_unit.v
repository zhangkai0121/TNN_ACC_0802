module select_unit(clk,rst_n,select_in,kernel,select_out);

input   clk;
input   rst_n;
input   select_in;
input   kernel;
output  select_out;

parameter FEATURE_WIDTH = 32; 
parameter KERNEL_WIDTH = 2;


wire  signed [FEATURE_WIDTH-1:0]                            select_in;
wire  signed [KERNEL_WIDTH - 1 : 0]                         kernel;
reg   signed [FEATURE_WIDTH-1:0]                            select_out;


always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            select_out <= 0;
        else
            begin
            if(kernel == 1)
                select_out <= select_in;
            else if(kernel == -1)
                select_out <= -select_in;
            else 
                select_out <= 0;
            end
    end
endmodule