module datapath (
    input                clk, reset,
    input                StallF_i,
    output reg    [31:0] PCF_o,
    input                StallD_i,
    input         [31:0] InstrF_i,
    output wire    [6:0] op_o,
    output wire    [2:0] funct3_o,
    output wire          funct7b5_o,
    input                RegWriteW_i,
    input          [2:0] ImmSrcD_i,
    output wire    [4:0] Rs1D_o,
    output wire    [4:0] Rs2D_o,
    input  wire          FlushE_i,
    output reg     [4:0] Rs1E_o,
    output reg     [4:0] Rs2E_o,
    output reg     [4:0] RdE_o,
    input                ALUSrcE_i,
    input          [2:0] ALUControlE_i,
    input          [1:0] ForwardAE_i,
    input          [1:0] ForwardBE_i,
    output               ZeroE_o,
    output logic [2:0]   funct3M_o,
    output reg     [4:0] RdM_o,
    output reg    [31:0] ALUResultM_o,
    output reg    [31:0] WriteDataM_o,
    input         [31:0] ReadDataM_i,
    input          [1:0] ResultSrcW_i,
    output reg     [4:0] RdW_o,
    input          [1:0] ResultSrcM_i,
    output wire [31:0] PCTargetE_o,
    input BranchTaken_i,
    input [31:0] BTBtarget_i,
    output wire GHRreset_o,
    input wire PHTincrement_i,
    input JumpE_i,
    output wire [6:0] branchop_o,
    output wire MisspredictE_o,
    input BranchE_i,
    input PCSelE_i,
    input JalrE_i,
    output wire BranchTakenE_o
);

`include "defines.vh"

// Define signals earleir if needed here

reg [31:0] ResultW;
reg BranchTaken_d, BranchTaken_e;
wire [31:0] PCTargetE;
reg [31:0] PCPlus4E;
// Misprediction detection:
//  - jalr: always redirect (BTB target unreliable — return addr varies per call).
//  - jal:  redirect if prediction was not-taken (BranchTaken_e != 1, even when X after flush).
//  - branch: only redirect when BranchTaken_e is known; ignore X (suppress false mispredictions).
assign MisspredictE_o = JalrE_i   ? JumpE_i :
                        JumpE_i   ? (BranchTaken_e !== 1'b1) :
                        (BranchE_i && (BranchTaken_e !== 1'bx) && (BranchTakenE !== 1'bx)) ?
                            (BranchTaken_e != BranchTakenE) : 1'b0;
assign GHRreset_o = MisspredictE_o | FlushE_i; // new flushE

always @(posedge clk or posedge reset) begin
  if (reset) begin
    BranchTaken_d <= 1'b0;
    BranchTaken_e <= 1'b0;
  end else begin
    if (MisspredictE_o)
      BranchTaken_d <= 1'bx;
    else
      BranchTaken_d <= BranchTaken_i;
    if (GHRreset_o)
      BranchTaken_e <= 1'bx;
    else
      BranchTaken_e <= BranchTaken_d;
  end
end

assign branchop_o = InstrF_i[6:0];


// ***** FETCH STAGE *********************************

// Mux feeding to PC
assign PCTargetE = (BranchTaken_e && !PHTincrement_i && BranchE_i) ? PCPlus4E : PCTargetE_o;
wire [31:0] PCPlus4F = PCF_o + 32'd4;
wire [31:0] PCTargetF = BranchTaken_i ? BTBtarget_i : PCPlus4F;
wire [31:0] PCnewF = MisspredictE_o ? PCTargetE : PCTargetF;

// Update registers
always @ (posedge clk) begin
    if (reset)        PCF_o <= PcStart;
    else if (!StallF_i) PCF_o <= PCnewF;
end

// ***** DECODE STAGE ********************************
reg [31:0] InstrD, PCPlus4D, PCD;
wire [4:0] RdD;

assign op_o       = InstrD[6:0];
assign funct3_o   = InstrD[14:12];
assign funct7b5_o = InstrD[30];
assign Rs1D_o = InstrD[19:15];
assign Rs2D_o = InstrD[24:20];
assign RdD = InstrD[11:7];

// Register File
wire [31:0] RD1D, RD2D;
rf rf (
    .clk(~clk),
    .a1_i(Rs1D_o), .a2_i(Rs2D_o), .a3_i(RdW_o),
    .rd1_o(RD1D), .rd2_o(RD2D),
    .we3_i(RegWriteW_i), .wd3_i(ResultW)
);

// Sign extension
reg [31:0] ExtImmD;

always_comb begin
   case(ImmSrcD_i)
      ImmItype: ExtImmD = {{20{InstrD[31]}},InstrD[31:20]};
      ImmStype: ExtImmD = {{20{InstrD[31]}},InstrD[31:25],InstrD[11:7]};
      ImmBtype: ExtImmD = {{20{InstrD[31]}},InstrD[7],InstrD[30:25], InstrD[11:8],1'b0};
      ImmJtype: ExtImmD = {{12{InstrD[31]}},InstrD[19:12],InstrD[20],InstrD[30:21],1'b0};
      ImmUtype: ExtImmD = {InstrD[31:12],12'b0};
      default:   ExtImmD = 32'hxxxx_xxxx;
//            `ifdef SIM
//            $warning("Unsupported ImmSrc given: %h", ImmSrc_i);
//            `else
//            ;
//            `endif
   endcase
end

// Update registers
always @ (posedge clk) begin
    if (reset | MisspredictE_o) begin
        InstrD   <= 32'b0;
        PCPlus4D <= 32'b0;
        PCD      <= 32'b0;
    end else if (!StallD_i) begin
        InstrD   <= InstrF_i;
        PCPlus4D <= PCPlus4F;
        PCD      <= PCF_o;
    end
end


// ***** EXECUTE STAGE ******************************
reg [31:0] RD1E, RD2E, ExtImmE, PCE;
reg [2:0]  funct3E;
reg [31:0] ForwardDataM;

// Forwarding muxes
reg  [31:0] SrcAE;
always_comb begin
    case (ForwardAE_i)
       ForwardMem: SrcAE = ALUResultM_o;
        ForwardWb: SrcAE = ResultW;
        ForwardEx: SrcAE = PCSelE_i ? PCE : RD1E;
       default: SrcAE = 32'hxxxx_xxxx;
    endcase
end

reg  [31:0] SrcBE;
reg  [31:0] WriteDataE;
always_comb begin
    case (ForwardBE_i)
       ForwardMem: WriteDataE = ForwardDataM;
        ForwardWb: WriteDataE = ResultW;
        ForwardEx: WriteDataE = RD2E;
       default: WriteDataE = 32'hxxxx_xxxx;
    endcase
end


// Mux feeding ALU Src B
always_comb begin
    case (ALUSrcE_i)
        SrcBImm: SrcBE = ExtImmE;
        SrcBReg: SrcBE = WriteDataE;
      default: SrcBE = 32'hxxxx_xxxx;
    endcase
end


// ALU
wire [31:0] ALUResultE;
alu alu (
    .a_i(SrcAE), .b_i(SrcBE),
    .alucontrol_i(ALUControlE_i),
    .result_o(ALUResultE),
    .zero_o(ZeroE_o)
);

// Branch taken condition — evaluated from rs1 (SrcAE) vs rs2 (WriteDataE)
// Uses direct comparison to correctly handle all 6 RISC-V branch types.
reg BranchTakenE;
always_comb begin
    case (funct3E)
        3'b000: BranchTakenE = (SrcAE == WriteDataE);           // beq
        3'b001: BranchTakenE = (SrcAE != WriteDataE);           // bne
        3'b100: BranchTakenE = ($signed(SrcAE) < $signed(WriteDataE));  // blt
        3'b101: BranchTakenE = ($signed(SrcAE) >= $signed(WriteDataE)); // bge
        3'b110: BranchTakenE = (SrcAE < WriteDataE);            // bltu
        3'b111: BranchTakenE = (SrcAE >= WriteDataE);           // bgeu
        default: BranchTakenE = 1'b0;
    endcase
end
assign BranchTakenE_o = BranchTakenE;

// PC Target — jalr uses rs1+imm (SrcAE+ExtImmE), everything else uses PC+imm.
assign PCTargetE_o = JalrE_i ? (SrcAE + ExtImmE) : (PCE + ExtImmE);

// Update registers
always @ (posedge clk) begin
    if (reset | GHRreset_o) begin
        RD1E     <= 32'b0;
        RD2E     <= 32'b0;
        PCE      <= 32'b0;
        ExtImmE  <= 32'b0;
        PCPlus4E <= 32'b0;
        Rs1E_o   <=  5'b0;
        Rs2E_o   <=  5'b0;
        RdE_o    <=  5'b0;
        funct3E  <=  3'b0;
    end else begin
        RD1E     <= RD1D;
        RD2E     <= RD2D;
        PCE      <= PCD;
        ExtImmE  <= ExtImmD;
        PCPlus4E <= PCPlus4D;
        Rs1E_o   <= Rs1D_o;
        Rs2E_o   <= Rs2D_o;
        RdE_o    <= RdD;
        funct3E  <= funct3_o;
    end
end


// ***** MEMORY STAGE ***************************
reg [31:0] ExtImmM, PCPlus4M;

always_comb begin
   case(ResultSrcM_i)
     MuxResultAluout:  ForwardDataM = ALUResultM_o;
     MuxResultPCPlus4: ForwardDataM = PCPlus4M;
     MuxResultImm:     ForwardDataM = ExtImmM;
     default:           ForwardDataM = 32'hxxxx_xxxx;

   endcase
 end

// Update registers
always @ (posedge clk) begin
    if (reset) begin
        ALUResultM_o <= 32'b0;
        WriteDataM_o <= 32'b0;
        ExtImmM      <= 32'b0;
        PCPlus4M     <= 32'b0;
        RdM_o        <=  5'b0;
        funct3M_o      <=  3'b0;
    end else begin
        ALUResultM_o <= ALUResultE;
        WriteDataM_o <= WriteDataE;
        ExtImmM      <= ExtImmE;
        PCPlus4M     <= PCPlus4E;
        RdM_o        <= RdE_o;
        funct3M_o      <= funct3E;
    end
end

// ***** WRITEBACK STAGE ************************
reg [31:0] PCPlus4W, ALUResultW, ReadDataW, ExtImmW;

always_comb begin
   case(ResultSrcW_i)
     MuxResultMem:     ResultW = ReadDataW;
     MuxResultAluout:  ResultW = ALUResultW;
     MuxResultPCPlus4: ResultW = PCPlus4W;
     MuxResultImm:     ResultW = ExtImmW;
     default:        ResultW = 32'hxxxx_xxxx;
  //          `ifdef SIM
  //          $warning("Unsupported ResultSrc given: %h", ResultSrc_i);
  //          `else
  //          ;
  //          `endif

  //   end
   endcase
 end

// Update registers
always @ (posedge clk) begin
    if (reset) begin
        ALUResultW <= 32'b0;
        ReadDataW  <= 32'b0;
        ExtImmW    <= 32'b0;
        PCPlus4W   <= 32'b0;
        RdW_o      <=  5'b0;
    end else begin
        ALUResultW <= ALUResultM_o;
        ReadDataW  <= ReadDataM_i;
        ExtImmW    <= ExtImmM;
        PCPlus4W   <= PCPlus4M;
        RdW_o      <= RdM_o;
    end
end

reg [31:0] total_JB;
reg [31:0] correct_JB;
reg [31:0] incorrect_JB;

// branch prediction data counter
always @(posedge clk or posedge reset) begin
  if (reset) begin
    total_JB <= 0;
    correct_JB <= 0;
    incorrect_JB <= 0;
  end else if (JumpE_i | BranchE_i) begin
    total_JB <= total_JB + 1;
    if (MisspredictE_o)
      incorrect_JB <= incorrect_JB + 1;
    else
      correct_JB <= correct_JB + 1;
  end
end


endmodule
