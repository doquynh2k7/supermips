package pipTypes;
  typedef enum {
                FWD_NONE,
                FWD_FROM_EXMEM,
                FWD_FROM_MEMWB,
                FWD_FROM_MEMWB_LATE
                } fwd_t;

  typedef enum {
                OP_ADD,
                OP_SUB,
                OP_OR,
                OP_XOR,
                OP_NOR,
                OP_AND,
                OP_LUI,
                OP_MUL_LO,
                OP_PASS_A,
                OP_PASS_B,
                OP_MOVZ,
                OP_MOVN,
                OP_SEB,
                OP_SEH,
                OP_EXT,
                OP_INS
                } alu_op_t;

  typedef enum {
                OP_NONE,
                OP_MUL,
                OP_DIV,
                OP_MADD,
                OP_MFHI,
                OP_MFLO,
                OP_MTHI,
                OP_MTLO
                } muldiv_op_t;

  typedef enum {
                RES_ALU,
                RES_SET,
                RES_SHIFT
                } alu_res_t;


  typedef enum {
                OP_LS_WORD,
                OP_LS_HALFWORD,
                OP_LS_BYTE
                } ls_op_t;

  typedef enum {
                COND_UNCONDITIONAL,
                COND_EQ,
                COND_NE,
                COND_GT,
                COND_LT,
                COND_GE,
                COND_LE
               } cond_t;


  // Total size, approx: 203 bits (171 without inst_word)
  typedef struct {
    // (64 bits)
    bit [31:0]   pc;
    bit [31:0]   inst_word;

    // branch unit signals (~39 bits [assuming one-hot])
    cond_t       branch_cond;
    bit [31:0]   branch_target;

    // source registers (12 bits)
    bit [ 4:0]   A_reg;
    bit          A_reg_valid;
    bit [ 4:0]   B_reg;
    bit          B_reg_valid;

    // extra source reg (6 bits)
    bit [ 4:0]   C_reg;
    bit          C_reg_valid;

    // destination register (6 bits)
    bit [ 4:0]   dest_reg;
    bit          dest_reg_valid;

    // immediate value (33 bits)
    bit [31:0]   imm;
    bit          imm_valid;

    // Shifter signals (9 bits)
    bit [ 4:0]   shamt;
    bit          shamt_valid;
    bit          shleft;
    bit          sharith;
    bit          shopsela;

    // ALU/EX signals (~20 bits [assuming one-hot])
    alu_op_t     alu_op;
    alu_res_t    alu_res_sel;
    bit          alu_set_u;

    // multiplier/divider signals (~9 bits [assuming one-hot])
    muldiv_op_t  muldiv_op;
    bit          muldiv_op_u;

    // load/store unit signals (4 bits [assuming one-hot])
    ls_op_t      ls_op;
    bit          ls_sext;

    // generic signals identifying instruction type (7 bits)
    bit          alu_inst;
    bit          muldiv_inst;
    bit          load_inst;
    bit          store_inst;
    bit          jmp_inst;
    bit          branch_inst;
    bit          nop;
  } dec_inst_t;


  typedef struct {
    bit          A_fwd_from_rfile;
    bit [ 3:0]   A_fwd_rob_idx;
    bit          B_fwd_from_rfile;
    bit [ 3:0]   B_fwd_rob_idx;
    bit          C_fwd_from_rfile;
    bit [ 3:0]   C_fwd_rob_idx;
  } fwd_info_t;


  typedef struct {
    bit          ready;
    bit          almost_ready;
  } fwd_status_t;


  typedef struct {
    bit [ 4:0]   rob_entry;
    bit          rfile;
  } rob_reg_info_t;


  typedef struct {
    bit [ 4:0]   dest_reg;
    bit          dest_reg_valid;
  } dest_reg_t;


  typedef struct {
    bit [31:0]   result_hi;
    bit [31:0]   result_lo;
    bit [ 4:0]   dest_reg;
    bit          dest_reg_valid;
    bit          pc_valid; // for flushing
  } rob_entry_t;


  typedef struct {
    dec_inst_t   dec_inst;
    fwd_info_t   fwd_info;
  } iq_entry_t;

endpackage
