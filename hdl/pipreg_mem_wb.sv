// NOTE: THIS MODULE IS AUTOGENERATED
//       DO NOT EDIT BY HAND!
module pipreg_mem_wb(

  input [31:0] mem_pc,
  input [31:0] mem_result,
  input [4:0] mem_dest_reg,
  input [0:0] mem_dest_reg_valid,


  output reg [31:0] wb_pc,
  output reg [31:0] wb_result,
  output reg [4:0] wb_dest_reg,
  output reg [0:0] wb_dest_reg_valid,

  input clock,
  input reset_n
);

  always_ff @(posedge clock, negedge reset_n) begin
    if (~reset_n) begin
    
      wb_pc <= 'b0;
      wb_result <= 'b0;
      wb_dest_reg <= 'b0;
      wb_dest_reg_valid <= 'b0;
    end
    else begin
    
      wb_pc <= mem_pc;
      wb_result <= mem_result;
      wb_dest_reg <= mem_dest_reg;
      wb_dest_reg_valid <= mem_dest_reg_valid;
    end
  end

endmodule
