module btb #(
  parameter int unsigned NUM_BTB_ENTRIES = 32
) (
  input               clk,
  input               reset_i,
  input        [31:0] pc_i,
  input        [31:0] BTBwritedata_i,
  input               J_i,
  input               B_i,
  output reg   [31:0] BTBtarget_o,
  output reg          jumphit_o,
  output reg          branchhit_o,
  output reg          branchtaken_en,
  input               PHTincrement_i
);

  localparam int unsigned Log2Btb = $clog2(NUM_BTB_ENTRIES);

  reg [31-2-Log2Btb:0] Tag    [NUM_BTB_ENTRIES];
  reg          [31:0]  Target [NUM_BTB_ENTRIES];
  reg                  J      [NUM_BTB_ENTRIES];
  reg                  B      [NUM_BTB_ENTRIES];
  reg        cache_hit;
  reg [31:0] pc_d;
  reg [31:0] pc_e;
  reg        cache_hit_d;
  reg        cache_hit_e;
  reg        BTB_write;
  wire [Log2Btb-1:0] btb_index;
  assign btb_index = pc_i[Log2Btb+1:2];
  integer i;

  always_comb begin
    if ((Tag[btb_index] == pc_i[31:Log2Btb+2]) && (J[btb_index] || B[btb_index])) begin
      cache_hit      = 1'b1;
      branchtaken_en = 1'b1;
    end else begin
      cache_hit      = 1'b0;
      branchtaken_en = 1'b0;
    end
    BTB_write = (!cache_hit_e && (J_i || PHTincrement_i));
  end

  always_comb begin
    if (cache_hit) begin
      BTBtarget_o = Target[btb_index];
      jumphit_o   = J[btb_index];
      branchhit_o = B[btb_index];
    end else begin
      BTBtarget_o = 32'b0;
      jumphit_o   = 1'b0;
      branchhit_o = 1'b0;
    end
  end

  always @(posedge clk or posedge reset_i) begin
    if (reset_i) begin
      pc_d        <= 32'b0;
      pc_e        <= 32'b0;
      cache_hit_d <= 1'b1;
      cache_hit_e <= 1'b1;
    end else begin
      pc_d        <= pc_i;
      pc_e        <= pc_d;
      cache_hit_d <= cache_hit;
      cache_hit_e <= cache_hit_d;
    end
  end

  always @(posedge clk or posedge reset_i) begin
    if (reset_i) begin
      for (i = 0; i < NUM_BTB_ENTRIES; i = i + 1) begin
        Tag[i]    <= 0;
        Target[i] <= 0;
        J[i]      <= 1'b0;
        B[i]      <= 1'b0;
      end
    end else begin
      if (BTB_write) begin
        Tag[pc_e[Log2Btb+1:2]]    <= pc_e[31:Log2Btb+2];
        Target[pc_e[Log2Btb+1:2]] <= BTBwritedata_i;
        J[pc_e[Log2Btb+1:2]]      <= J_i;
        B[pc_e[Log2Btb+1:2]]      <= B_i;
      end
    end
  end

endmodule
