module branch #(
  parameter int unsigned NUM_GHR_BITS = 3
) (
  input               clk,
  input               reset_i,
  input        [31:0] pc_i,
  input        [31:0] BTBwritedata_i,
  output reg   [31:0] BTBtarget_o,
  output reg          BranchTaken_o,
  input         [6:0] branchop_i,
  input               PHTincrement_i,
  input               GHRreset_i,
  input               MisspredictE_i
);

`include "defines.vh"

wire jumphit, branchhit, branchtaken_en;
reg [NUM_GHR_BITS-1:0] GHR;
reg B_type, J_type;
reg B_d, J_d;
reg B_e, J_e;
wire predict_taken;
reg [NUM_GHR_BITS-1:0] PHTreadaddress;
wire [31:0] BTBtarget_internal;

btb b0 (
  .clk(clk),
  .reset_i(reset_i),
  .pc_i(pc_i),
  .BTBwritedata_i(BTBwritedata_i),
  .J_i(J_e),
  .B_i(B_e),
  .BTBtarget_o(BTBtarget_internal),
  .jumphit_o(jumphit),
  .branchhit_o(branchhit),
  .branchtaken_en(branchtaken_en),
  .PHTincrement_i(PHTincrement_i)
);

pht #(
  .NUM_GHR_BITS(NUM_GHR_BITS)
) p0 (
  .clk(clk),
  .reset_i(reset_i),
  .PHTreadaddress_o(PHTreadaddress),
  .PHTincrement_i(PHTincrement_i),
  .B_i(B_e),
  .predict_taken(predict_taken)
);

always_comb begin
  B_type        = (branchop_i == 7'd99);
  J_type        = (branchop_i == 7'd103 || branchop_i == 7'd111);
  BranchTaken_o = branchtaken_en & ((predict_taken & branchhit) | jumphit);
  PHTreadaddress = pc_i[NUM_GHR_BITS+1:2] ^ GHR;
  BTBtarget_o   = BTBtarget_internal;
end

always @(posedge clk or posedge reset_i) begin
  if (reset_i || GHRreset_i)
    GHR <= 0;
  else if (B_type)
    GHR <= {predict_taken, GHR[NUM_GHR_BITS-1:1]};
end

always @(posedge clk or posedge reset_i) begin
  if (reset_i) begin
    B_d <= 1'b0;
    B_e <= 1'b0;
    J_d <= 1'b0;
    J_e <= 1'b0;
  end else if (MisspredictE_i) begin
    B_d <= 1'b0;
    J_d <= 1'b0;
    B_e <= 1'b0;
    J_e <= 1'b0;
  end else if (GHRreset_i) begin
    B_d <= B_type;
    J_d <= J_type;
    B_e <= 1'b0;
    J_e <= 1'b0;
  end else begin
    B_d <= B_type;
    J_d <= J_type;
    B_e <= B_d;
    J_e <= J_d;
  end
end

endmodule
