// defines.vh


// Misc
localparam logic [31:0] PcStart = 32'h00010000;

// ***** FETCH STAGE ****
// Mux to feed PC for mispredicts
localparam logic [0:0] MuxPCNewFromFetch    = 1'b0;
localparam logic [0:0] MuxPCNewFromExecute  = 1'b1;

// Mux to choose between PC+4 or BTB
localparam logic [0:0] MuxPCTargetFromPCPlus4   = 1'b0;
localparam logic [0:0] MuxPCTargetFromBTB       = 1'b1;


// **** DECODE STAGE ****
// Control unit (instruction Funct3 codes)
localparam logic [2:0] InstrAddsubFunct3 = 3'b000;
localparam logic [2:0] InstrSltFunct3    = 3'b010;
localparam logic [2:0] InstrOrFunct3     = 3'b110;
localparam logic [2:0] InstrAndFunct3    = 3'b111;

localparam logic [2:0] InstrBeqFunct3    = 3'b000;
localparam logic [2:0] InstrBneFunct3    = 3'b001;

// Control unit (instruction Op codes)
localparam logic [6:0] InstrRtypeOp    = 7'b0110011;
localparam logic [6:0] InstrLwOp       = 7'b0000011;
localparam logic [6:0] InstrSwOp       = 7'b0100011;
localparam logic [6:0] InstrJalOp      = 7'b1101111;
localparam logic [6:0] InstrBranchOp   = 7'b1100011;
localparam logic [6:0] InstrItypeALUOp = 7'b0010011;
localparam logic [6:0] InstrLuiOp      = 7'b0110111;
localparam logic [6:0] InstrAuipcOp    = 7'b0010111;
localparam logic [6:0] InstrJalrOp     = 7'b1100111;


// Control unit (ALU op codes)
localparam logic [1:0] ALUopMem    = 2'b00;
localparam logic [1:0] ALUopBeqbne = 2'b01;
localparam logic [1:0] ALUopOther  = 2'b10;

// Extend Unit (ImmSrc codes)
localparam logic [2:0] ImmItype = 3'b000;
localparam logic [2:0] ImmStype = 3'b001;
localparam logic [2:0] ImmBtype = 3'b010;
localparam logic [2:0] ImmJtype = 3'b011;
localparam logic [2:0] ImmUtype = 3'b100;


// **** EXECUTE STAGE ****
// ALU (ALUControl codes)
localparam logic [2:0] ALUcontrolAdd = 3'b000;
localparam logic [2:0] ALUcontrolSub = 3'b001;
localparam logic [2:0] ALUcontrolAnd = 3'b010;
localparam logic [2:0] ALUcontrolOr  = 3'b011;
localparam logic [2:0] ALUcontrolSlt = 3'b101;

// Mux (Forwarding inputs to ALU)
localparam logic [1:0] ForwardEx    = 2'b00;
localparam logic [1:0] ForwardWb    = 2'b01;
localparam logic [1:0] ForwardMem   = 2'b10;

// Mux (Feeding ALU SrcB input)
localparam logic SrcBReg  = 1'b0;
localparam logic SrcBImm  = 1'b1;


// **** MEMORY STAGE ****


// **** WRITEBACK STAGE ****
// Mux (supplying ResultW)
localparam logic [1:0] MuxResultAluout  = 2'b00;
localparam logic [1:0] MuxResultMem     = 2'b01;
localparam logic [1:0] MuxResultPCPlus4 = 2'b10;
localparam logic [1:0] MuxResultImm     = 2'b11;


