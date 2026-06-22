module alu (
    input  logic [31:0] a_i, b_i,
    input  logic  [2:0] alucontrol_i,
    output logic [31:0] result_o,
    output logic        zero_o
);

`include "defines.vh"

always_comb begin
    case (alucontrol_i)
        ALUcontrolAnd: result_o = a_i & b_i;
        ALUcontrolOr:  result_o = a_i | b_i;
        ALUcontrolAdd: result_o = a_i + b_i;
        ALUcontrolSub: result_o = a_i - b_i;
        ALUcontrolSlt: result_o = {31'b0, ($signed(a_i) < $signed(b_i))};
        default: begin
            `ifdef SIM
                $warning("Unsupported ALUOp given: %h", alucontrol_i);
            `endif
            result_o = 'x;
        end
    endcase
end

assign zero_o = (result_o == 32'b0);

endmodule
