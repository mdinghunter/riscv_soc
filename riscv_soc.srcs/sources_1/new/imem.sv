`define MIN(A,B) (((A)<(B))?(A):(B))

module imem #(
    parameter int unsigned TEXT_SIZE = 2048
) (
    input        [31:0] a_i,
    input        [31:0] b_i,
    output wire  [31:0] a_rd_o,
    output wire  [31:0] b_rd_o,
    output wire          b_hit_o      // high when b_i falls in text range
);

reg [31:0] TEXT [TEXT_SIZE];

initial $readmemh("text.dat", TEXT);

// Synthesis fallback: if text.dat is missing, fill TEXT with NOPs so the
// array always has a driver.  Without this Vivado trims the entire CPU.
`ifndef SIM
generate
    genvar _i;
    for (_i = 0; _i < TEXT_SIZE; _i = _i + 1) begin : text_init
        initial TEXT[_i] = 32'h00000013;  // addi x0, x0, 0  (NOP)
    end
endgenerate
`endif

localparam logic [31:0] TextStart = 32'h00010000;
localparam logic [31:0] TextEnd   = `MIN(TextStart + (TEXT_SIZE * 4), 32'h10000000);
localparam int unsigned TextAddressWidth = $clog2(TEXT_SIZE);

wire a_text_enable = (TextStart <= a_i) && (a_i < TextEnd);
wire b_text_enable = (TextStart <= b_i) && (b_i < TextEnd);

wire [TextAddressWidth-1:0] a_text_address =
    a_i[2 +: TextAddressWidth] - TextStart[2 +: TextAddressWidth];
wire [TextAddressWidth-1:0] b_text_address =
    b_i[2 +: TextAddressWidth] - TextStart[2 +: TextAddressWidth];

wire [31:0] a_text_data = TEXT[a_text_address];
wire [31:0] b_text_data = TEXT[b_text_address];

// No tristate — instruction fetch port always enabled; data port uses hit flag
assign a_rd_o  = a_text_data;
assign b_rd_o  = b_text_data;
assign b_hit_o = b_text_enable;

`ifdef SIM
always_comb begin
    if (a_i[1:0] != 2'b00)
        $warning("Attempted to access invalid address 0x%h. Address coerced to 0x%h.",
                 a_i, (a_i & (~32'b00000000_00000000_00000000_00000011)));
    if (b_i[1:0] != 2'b00)
        $warning("Attempted to access invalid address 0x%h. Address coerced to 0x%h.",
                 b_i, (b_i & (~32'b00000000_00000000_00000000_00000011)));
end
`endif

endmodule

`undef MIN
