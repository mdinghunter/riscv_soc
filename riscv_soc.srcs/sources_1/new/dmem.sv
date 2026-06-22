// ### 1. Byte/Halfword Memory (lb/lh/lbu/lhu/sb/sh)
// - Add byte-enable strobes (4-bit we) to dmem
// - Barrel-shifter for sub-word data extraction/alignment
// - Sign/zero-extension mux in writeback
// - ~50 lines of Verilog, unlocks real C code using char/short/structs

`define MIN(A,B) (((A)<(B))?(A):(B))

module dmem #(
    parameter int unsigned DATA_SIZE = 1024
) (
    input               clk, we_i,
    input        [31:0] a_i,
    input        [31:0] wd_i,
    input        [2:0] funct3_i,  // for lb/lh/lbu/lhu/sb/sh
    output wire  [31:0] rd_o,
    output wire          hit_o      // high when a_i falls in data range
);

reg [31:0] DATA [DATA_SIZE];

localparam logic [31:0] DataStart = 32'h10000000;
localparam logic [31:0] DataEnd   = `MIN(DataStart + (DATA_SIZE * 4), 32'h80000000);
localparam int unsigned DataAddressWidth = $clog2(DATA_SIZE);

wire data_enable = (DataStart <= a_i) && (a_i < DataEnd);

wire [DataAddressWidth-1:0] data_address =
    a_i[2 +: DataAddressWidth] - DataStart[2 +: DataAddressWidth];

wire [31:0] data_data = DATA[data_address];

logic [31:0] rd_shft = data_data >> {a_i[1:0], 3'b0};  // shift by byte_offset*8
logic [31:0] wr_shft = wd_i >> {a_i[1:0], 3'b0};     // shift by byte_offset*8

// loading logic
always_comb begin
    case (funct3_i)
        3'b000: // lb
            rd = {{24{rd_shft[7]}},  rd_shft[7:0]};
        3'b001: // lh
            rd_o = {{16{rd_shft[15]}}, rd_shft[15:0]};
        3'b010: // lw
            rd_o = data_data;
        3'b100: // lbu
            rd_o = {24'b0, rd_shft[7:0]};
        3'b101: // lhu
            rd_o = {16'b0, rd_shft[15:0]};
        default:
            rd_o = 32'h0;
    endcase
end

// No tristate — use hit_o to tell top whether to use this result
assign hit_o = data_enable;

// Write port (single process for clean BRAM inference)
always @(posedge clk) begin
    if (we_i) begin
        if (data_enable)
            case (funct3_i)
                3'b000: // sb
                    DATA[data_address] <= (DATA[data_address] & ~(32'hFF << (8 * a_i[1:0]))) |
                                        ((wd_i[7:0] << (8 * a_i[1:0])));
                3'b001: // sh
                    DATA[data_address] <= (DATA[data_address] & ~(32'hFFFF << (16 * a_i[1]))) |
                                        ((wd_i[15:0] << (16 * a_i[1])));
                3'b010: // sw
                    DATA[data_address] <= wd_i;
                default:
                    ;
            endcase
`ifdef SIM
        if (a_i[1:0] != 2'b00)
            $warning("Attempted to write to invalid address 0x%h. Address coerced to 0x%h.",
                     a_i, (a_i & (~32'b00000000_00000000_00000000_00000011)));
        if (!data_enable)
            $warning("Attempted to write to out-of-range address 0x%h.",
                     (a_i & (~32'b00000000_00000000_00000000_00000011)));
`endif
    end
end

endmodule

`undef MIN
