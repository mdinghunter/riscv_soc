module controller (
    input                clk, reset,
    input         [6:0]  op_i,
    input         [2:0]  funct3_i,
    input                funct7b5_i,
    input                ZeroE_i,
    input         [4:0]  Rs1D_i,
    input         [4:0]  Rs2D_i,
    input         [4:0]  Rs1E_i,
    input         [4:0]  Rs2E_i,
    input         [4:0]  RdE_i,
    input         [4:0]  RdM_i,
    input         [4:0]  RdW_i,
    output wire          StallF_o,
    output wire          StallD_o,
    output wire    [2:0] ImmSrcD_o,
    output reg     [2:0] ALUControlE_o,
    output reg           ALUSrcE_o,
    output wire          FlushE_o,
    output reg     [1:0] ForwardAE_o,
    output reg     [1:0] ForwardBE_o,
    output reg           MemWriteM_o,
    output reg           RegWriteW_o,
    output reg     [1:0] ResultSrcW_o,
    output reg     [1:0] ResultSrcM_o,
    output wire          PHTincrement_o,
    output reg           JumpE_o,
    output reg           BranchE_o,
    output reg           PCSelE_o,
    output reg           JalrE_o,
    input                BranchTakenE_i,
    input                MisspredictE_i
);

`include "defines.vh"

// ***** DECODE STAGE **************************************
wire RegWriteD, MemWriteD, JumpD, BranchD, ALUSrcD;
wire [1:0] ResultSrcD;
reg  [2:0] ALUControlD;
wire [1:0] ALUOpD;

// maindecoderD packs all decode-stage control signals into one reg for
// case-statement assignment; split out via continuous assign below.
reg [11:0] maindecoderD;

assign {RegWriteD,
        ImmSrcD_o,
        ALUSrcD,
        MemWriteD,
        ResultSrcD,
        BranchD,
        ALUOpD,
        JumpD} = maindecoderD;

always_comb begin
    case (op_i)
        InstrLwOp:       maindecoderD = 12'b1_000_1_0_01_0_00_0;
        InstrSwOp:       maindecoderD = 12'b0_001_1_1_00_0_00_0;
        InstrRtypeOp:    maindecoderD = 12'b1_xxx_0_0_00_0_10_0;
        InstrBranchOp:   maindecoderD = 12'b0_010_0_0_00_1_01_0;
        InstrItypeALUOp: maindecoderD = 12'b1_000_1_0_00_0_10_0;
        InstrJalOp:      maindecoderD = 12'b1_011_x_0_10_0_xx_1;
        InstrLuiOp:      maindecoderD = 12'b1_100_x_0_11_0_xx_0;
        InstrAuipcOp:    maindecoderD = 12'b1_100_1_0_00_0_00_0;
        InstrJalrOp:     maindecoderD = 12'b1_000_x_0_10_0_xx_1;
        default: begin
            maindecoderD = 12'b0_000_0_0_00_0_00_0;
`ifdef SIM
            if (op_i !== 7'bxxxxxxx)
                $warning("controller: unknown opcode 7'b%07b at time %0t", op_i, $time);
`endif
        end
    endcase
end

wire RtypeSubD;
assign RtypeSubD = funct7b5_i & op_i[5];

always_comb begin
    case (ALUOpD)
        ALUopMem:    ALUControlD = ALUcontrolAdd;
        ALUopBeqbne: ALUControlD = ALUcontrolSub;
        ALUopOther:
            case (funct3_i)
                InstrAddsubFunct3:
                    if (RtypeSubD) ALUControlD = ALUcontrolSub;
                    else           ALUControlD = ALUcontrolAdd;
                InstrSltFunct3: ALUControlD = ALUcontrolSlt;
                InstrOrFunct3:  ALUControlD = ALUcontrolOr;
                InstrAndFunct3: ALUControlD = ALUcontrolAnd;
                default:          ALUControlD = 3'bxxx;
            endcase
        default: ALUControlD = 3'bxxx;
    endcase
end

wire PCSelD;
assign PCSelD = (op_i == InstrAuipcOp);

// ****** EXECUTE STAGE ****************************************
reg RegWriteE, MemWriteE;
reg [1:0] ResultSrcE;

assign PHTincrement_o = BranchE_o & BranchTakenE_i;

always @(posedge clk) begin
    if (FlushE_o | MisspredictE_i | reset) begin
        RegWriteE     <= 1'b0;
        ResultSrcE    <= 2'b0;
        MemWriteE     <= 1'b0;
        JumpE_o       <= 1'b0;
        BranchE_o     <= 1'b0;
        ALUControlE_o <= 3'b0;
        ALUSrcE_o     <= 1'b0;
        PCSelE_o      <= 1'b0;
        JalrE_o       <= 1'b0;
    end else begin
        RegWriteE     <= RegWriteD;
        ResultSrcE    <= ResultSrcD;
        MemWriteE     <= MemWriteD;
        JumpE_o       <= JumpD;
        BranchE_o     <= BranchD;
        ALUControlE_o <= ALUControlD;
        ALUSrcE_o     <= ALUSrcD;
        PCSelE_o      <= PCSelD;
        JalrE_o       <= (op_i == InstrJalrOp);
    end
end

// ***** MEMORY STAGE ******************************************
reg RegWriteM;

always @(posedge clk) begin
    if (reset) begin
        RegWriteM    <= 1'b0;
        ResultSrcM_o <= 2'b0;
        MemWriteM_o  <= 1'b0;
    end else begin
        RegWriteM    <= RegWriteE;
        ResultSrcM_o <= ResultSrcE;
        MemWriteM_o  <= MemWriteE;
    end
end

// ***** WRITEBACK STAGE ***************************************
always @(posedge clk) begin
    if (reset) begin
        RegWriteW_o  <= 1'b0;
        ResultSrcW_o <= 2'b0;
    end else begin
        RegWriteW_o  <= RegWriteM;
        ResultSrcW_o <= ResultSrcM_o;
    end
end

// Hazard unit — forwarding logic
always_comb begin
    if      ((Rs1E_i == RdM_i) & RegWriteM  & (Rs1E_i != 0)) ForwardAE_o = ForwardMem;
    else if ((Rs1E_i == RdW_i) & RegWriteW_o & (Rs1E_i != 0)) ForwardAE_o = ForwardWb;
    else                                                        ForwardAE_o = ForwardEx;
end

always_comb begin
    if      ((Rs2E_i == RdM_i) & RegWriteM  & (Rs2E_i != 0)) ForwardBE_o = ForwardMem;
    else if ((Rs2E_i == RdW_i) & RegWriteW_o & (Rs2E_i != 0)) ForwardBE_o = ForwardWb;
    else                                                        ForwardBE_o = ForwardEx;
end

// Stall logic
wire lwStall;
assign lwStall   = (ResultSrcE == 1) & ((Rs1D_i == RdE_i) | (Rs2D_i == RdE_i)) & (RdE_i != 0);
assign StallF_o  = lwStall;
assign StallD_o  = lwStall;
assign FlushE_o  = lwStall;

endmodule
