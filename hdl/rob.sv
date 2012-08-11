import pipTypes::*;

module rob #(
  parameter type T     = rob_entry_t,
  parameter      DEPTH     = 16,
                 INS_COUNT = 2,
                 EXT_COUNT = 2,
                 REG_COUNT = 32,
                 DEPTHLOG2 = $clog2(DEPTH),
                 EXTCOUNTLOG2  = $clog2(EXT_COUNT),
                 INSCOUNTLOG2  = $clog2(INS_COUNT)
)(
  input                      clock,
  input                      reset_n,

  // Reservation interface
  input                      reserve,
  input [INSCOUNTLOG2-1:0]   reserve_count,
  output reg [DEPTHLOG2-1:0] reserved_slots[INS_COUNT],
  output                     full,

  // Forwarding and forward querying interface (hand in hand with reserv. interface)
  input [4:0]                dest_reg[INS_COUNT],
  input                      dest_reg_valid[INS_COUNT],

  input [4:0]                A_reg[INS_COUNT],
  input [4:0]                B_reg[INS_COUNT],
  input [4:0]                C_reg[INS_COUNT],
  output                     fwd_info_t fwd_info[INS_COUNT],

  input [DEPTHLOG2-1:0]      A_rob_idx[INS_COUNT],
  input [DEPTHLOG2-1:0]      B_rob_idx[INS_COUNT],
  input [DEPTHLOG2-1:0]      C_rob_idx[INS_COUNT],
  output [31:0]              A_val[INS_COUNT],
  output [31:0]              B_val[INS_COUNT],
  output [31:0]              C_val[INS_COUNT],
  output                     A_val_valid[INS_COUNT],
  output                     B_val_valid[INS_COUNT],
  output                     C_val_valid[INS_COUNT],

  // Associate lookup interface
  input [DEPTHLOG2-1:0]      as_query_idx[INS_COUNT],
  input [4:0]                as_areg[INS_COUNT],
  input [4:0]                as_breg[INS_COUNT],
  input [4:0]                as_creg[INS_COUNT],
  output [31:0]              as_aval[INS_COUNT],
  output [31:0]              as_bval[INS_COUNT],
  output [31:0]              as_cval[INS_COUNT],
  output                     as_aval_valid[INS_COUNT],
  output                     as_bval_valid[INS_COUNT],
  output                     as_cval_valid[INS_COUNT],
  output                     as_aval_present[INS_COUNT],
  output                     as_bval_present[INS_COUNT],
  output                     as_cval_present[INS_COUNT],

  // Store interface
  input [DEPTHLOG2-1:0]      write_slot[INS_COUNT],
  input                      write_valid[INS_COUNT],
  input                      T write_data[INS_COUNT],

  // Retrieve interface
  input                      consume,
  input [EXTCOUNTLOG2-1:0]   consume_count,
  output                     T slot_data[EXT_COUNT],
  output reg                 slot_valid[EXT_COUNT],
  output                     empty,

  output reg [DEPTHLOG2:0]   used_count
);

  wire                     reserve_i;
  wire                     consume_i;
  wire [EXTCOUNTLOG2-1:0]  consume_count_i;

  reg [DEPTHLOG2-1:0]      ext_ptr;
  reg [DEPTHLOG2-1:0]      ins_ptr;

  T buffer[DEPTH];
  bit valid[DEPTH];
  bit in_transit[DEPTH];
  rob_reg_info_t reg_info[REG_COUNT];



  // Overflow and underflow protected signals
  assign reserve_i        = reserve & ~full;
  assign consume_i        = consume & ~empty;
  assign consume_count_i  = (consume_count >= used_count-1) ? (used_count-1) : consume_count;



  genvar i;
  generate
    for (i = 0; i < INS_COUNT; i++) begin
      assign A_val[i]        = buffer[A_rob_idx].result_lo;
      assign B_val[i]        = buffer[B_rob_idx].result_lo;
      assign C_val[i]        = buffer[C_rob_idx].result_lo;
      assign A_val_valid[i]  = valid[A_rob_idx];
      assign B_val_valid[i]  = valid[B_rob_idx];
      assign C_val_valid[i]  = valid[C_rob_idx];
    end
  endgenerate






  // High-level associative lookup interface
  always_comb begin
    for (integer i = 0; i < INS_COUNT; i++) begin
      as_aval_valid[i]    = 1'b0;
      as_aval_present[i]  = 1'b0;
      as_aval[i]          = 32'b0;


      for (bit [DEPTHLOG2-1:0] k = as_query_idx[i]-1; k >= ext_ptr; k--) begin
        if (buffer[k].dest_reg == as_areg[i] && buffer[k].dest_reg_valid) begin
          as_aval[i]          = buffer[k].result_lo;
          as_aval_valid[i]    = valid[k];
          as_aval_present[i]  = 1'b1;
          break;
        end
      end
    end
  end // always_comb

  always_comb begin
    for (integer i = 0; i < INS_COUNT; i++) begin
      as_bval_valid[i]    = 1'b0;
      as_bval_present[i]  = 1'b0;
      as_bval[i]          = 32'b0;


      for (bit [DEPTHLOG2-1:0] k = as_query_idx[i]-1; k >= ext_ptr; k--) begin
        if (buffer[k].dest_reg == as_breg[i] && buffer[k].dest_reg_valid) begin
          as_bval[i]          = buffer[k].result_lo;
          as_bval_valid[i]    = valid[k];
          as_bval_present[i]  = 1'b1;
          break;
        end
      end
    end
  end // always_comb

  always_comb begin
    for (integer i = 0; i < INS_COUNT; i++) begin
      as_cval_valid[i]    = 1'b0;
      as_cval_present[i]  = 1'b0;
      as_cval[i]          = 32'b0;


      for (bit [DEPTHLOG2-1:0] k = as_query_idx[i]-1; k >= ext_ptr; k--) begin
        if (buffer[k].dest_reg == as_creg[i] && buffer[k].dest_reg_valid) begin
          as_cval[i]          = buffer[k].result_lo;
          as_cval_valid[i]    = valid[k];
          as_cval_present[i]  = 1'b1;
          break;
        end
      end
    end
  end // always_comb





  // Reservation interface
  always_comb begin
    for (integer i = 0; i < INS_COUNT; i++)
      reserved_slots[i]  = ins_ptr + i;
  end

  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      ins_ptr <= 'b0;
    else if (reserve_i)
      ins_ptr <= ins_ptr + reserve_count + 1;


  // Common
  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      ;
    else
      for (integer i = 0; i < INS_COUNT; i++) begin
        if (reserve_i) begin
          valid[ins_ptr + i]      <= 1'b0;
          in_transit[ins_ptr + i] <= 1'b0;
        end
        if (write_valid[i])
          valid[write_slot[i]] <= 1'b1;
      end


  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      reg_info[0].rfile <= 1'b1; // $0 is always valid in reg file
    else begin
      if (consume_i) begin
        for (integer i = 0; i <= consume_count_i; i++) begin
          if (buffer[i].dest_reg_valid)
            reg_info[buffer[i].dest_reg] <= 1'b1;
        end
      end

      if (reserve_i) begin
        for (integer i = 0; i < INS_COUNT; i++) begin
          if (dest_reg_valid[i]) begin
            reg_info[dest_reg[i]].rfile   <= 1'b0;
            reg_info[dest_reg[i]].rob_idx <= ins_ptr + i;
          end
        end
      end
    end


  always_comb begin
    for (integer i = 0; i < INS_COUNT; i++) begin
      fwd_info[i].A_fwd_from_rfile  = reg_info[A_reg[i]].rfile;
      fwd_info[i].A_fwd_rob_idx     = reg_info[A_reg[i]].rob_idx;
      fwd_info[i].B_fwd_from_rfile  = reg_info[B_reg[i]].rfile;
      fwd_info[i].B_fwd_rob_idx     = reg_info[B_reg[i]].rob_idx;
      fwd_info[i].C_fwd_from_rfile  = reg_info[C_reg[i]].rfile;
      fwd_info[i].C_fwd_rob_idx     = reg_info[C_reg[i]].rob_idx;

      for (integer k = 0; k < i; k++) begin
        if (dest_reg_valid[k] && (dest_reg[k] == A_reg[i])) begin
          fwd_info[i].A_fwd_from_rfile  = 1'b0;
          fwd_info[i].A_fwd_rob_idx     = reserved_slots[k];
        end
        if (dest_reg_valid[k] && (dest_reg[k] == B_reg[i])) begin
          fwd_info[i].B_fwd_from_rfile  = 1'b0;
          fwd_info[i].B_fwd_rob_idx     = reserved_slots[k];
        end
        if (dest_reg_valid[k] && (dest_reg[k] == C_reg[i])) begin
          fwd_info[i].C_fwd_from_rfile  = 1'b0;
          fwd_info[i].C_fwd_rob_idx     = reserved_slots[k];
        end
      end
    end
  end



  // Store interface
  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      ;
    else
      for (integer i = 0; i < INS_COUNT; i++)
        if (write_valid[i])
          buffer[write_slot[i]] <= write_data[i];



  // Consume interface
  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      ext_ptr <= 'b0;
    else if (consume_i)
      ext_ptr <= ext_ptr + consume_count_i + 1;

  always_comb
    begin
      for (integer i = 0; i < INS_COUNT; i++) begin
        slot_data[i]   = buffer[ext_ptr + i];
        slot_valid[i]  = valid[ext_ptr + i];
      end
    end


  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      used_count <= 0;
    else
      used_count <=  used_count
                   + ((reserve_count   + 1) & {(INSCOUNTLOG2+1){reserve_i}})
                   - ((consume_count_i + 1) & {(EXTCOUNTLOG2+1){consume_i}});


  assign empty      = (used_count == 0);
  assign full       = (used_count > DEPTH-INS_COUNT);
endmodule
