module memory #(
                parameter ADDR_WIDTH = 32,
                          DATA_WIDTH = 32,
                          BURSTLEN_WIDTH = 2,
                          MEM_FILE = "",
                          DEPTH = 2*1024*1024
)(
  input [ADDR_WIDTH-1:0]      addr,
  input [BURSTLEN_WIDTH-1:0]  burst_len,
  output reg [DATA_WIDTH-1:0] data_out,
  input [DATA_WIDTH-1:0]      data_in,
  input                       wr,
  input                       rd,
  output                      waitrequest,
  output reg                  rd_valid
);

  typedef enum               { IDLE, BURST_READ } state_t;


  reg [BURSTLEN_WIDTH-1:0]   burst_count_r;

  reg [DATA_WIDTH-1:0]       mem[DEPTH];
  reg [BURSTLEN_WIDTH-1:0]   rem_bursts;
  wire [ADDR_WIDTH-1:0]      addr_int;
  reg [ADDR_WIDTH-1:0]       burst_addr;

  reg                        load_burst_count;
  reg                        dec_burst_count;


  state_t                    next_state;
  state_t                    state;


  assign addr_int  = addr >> $clog2(DATA_WIDTH/8);

  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      $readmemh(MEM_FILE, mem);
    else if (wr)
      mem[addr_int] <= data_in;



  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n) begin
      burst_count_r <= 'b0;
      burst_addr    <= 'b0;
    end
    else if (load_burst_count) begin
      burst_count_r <= burst_len;
      burst_addr    <= addr_int;
    end
    else if (dec_burst_count && burst_count_r > 0) begin
      burst_count_r <= burst_count_r - 1;
      // XXX: insert wrap burst logic here
      burst_addr    <= burst_addr + 1;
    end


  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n) begin
      rd_valid <= 1'b0;
      data_out <= 'b0;
    end
    else begin
      rd_valid <= dec_burst_count;
      data_out <= mem[burst_addr];
    end


  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      state <= IDLE;
    else
      state <= next_state;


  always_comb
    begin
      next_state        = state;
      load_burst_count  = 1'b0;
      dec_burst_count   = 1'b0;


      case (state)
        IDLE: begin
          load_burst_count     = 1'b1;
          if (rd && burst_len != 0)
            next_state  = BURST_READ;
        end

        BURST_READ: begin
          dec_burst_count  = 1'b1;
          if (burst_count_r == 0)
            next_state  = IDLE;
        end
      endcase
    end


endmodule