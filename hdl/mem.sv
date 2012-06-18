module mem #(
  parameter ADDR_WIDTH = 32,
            DATA_WIDTH = 32
)(
  input                   clock,
  input                   reset_n,

  output                  cache_rd,
  output                  cache_wr,
  output [ADDR_WIDTH-1:0] cache_addr,
  output [DATA_WIDTH-1:0] cache_wr_data,
  input [DATA_WIDTH-1:0]  cache_data,
  input                   cache_waitrequest,

  input                   mem_inst, // XXX: break up into load_inst, store_inst

  input [ 4:0]            dest_reg,
  input                   dest_reg_valid,

  input [31:0]            alu_result, // soon to be agu_result

  output [31:0]           result
);

  // XXX: just pass ALU through, everything else is 0 result
  assign result   = (mem_inst) ? 32'b0 : alu_result;
  assign cache_wr = 1'b0;
  assign cache_rd = 1'b0;

endmodule // mem
