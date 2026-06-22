module top (
    input  CLK100MHZ,
    input  CPU_RESETN,           // active-low pushbutton
    output wire [7:0] gpio       // debug output — prevents synthesis trimming
);

wire clk   = CLK100MHZ;
wire reset = ~CPU_RESETN;

wire [31:0] pc, instr;
wire [31:0] writedata, dataadr;
wire        memwrite;

// Const read-only data lives in imem (.rodata), stack/bss in dmem.
// imem port B serves rodata loads; dmem serves stack/bss.
// Use hit signals to select the correct read data source.
wire [31:0] imem_rdata, dmem_rdata;
wire        imem_b_hit, dmem_hit;
wire [31:0] readdata = imem_b_hit ? imem_rdata : dmem_rdata;
logic [2:0] funct3M;

(* DONT_TOUCH = "true" *) riscv_pipe riscv (
    .clk(clk), .reset(reset),
    .PCF_o(pc),
    .InstrF_i(instr),
    .MemWriteM_o(memwrite),
    .ALUResultM_o(dataadr),
    .WriteDataM_o(writedata),
    .funct3M(funct3M),
    .ReadDataM_i(readdata)
);

(* DONT_TOUCH = "true" *) imem imem (
    .a_i(pc),       .b_i(dataadr),
    .a_rd_o(instr), .b_rd_o(imem_rdata),
    .b_hit_o(imem_b_hit)
);

(* DONT_TOUCH = "true" *) dmem dmem (
    .clk(clk), .we_i(memwrite),
    .a_i(dataadr), .wd_i(writedata),
    .funct3_i(funct3M),
    .rd_o(dmem_rdata),
    .hit_o(dmem_hit)
);

// Drive debug GPIO from PC to prevent synthesis from trimming the CPU
assign gpio = pc[7:0];

endmodule
