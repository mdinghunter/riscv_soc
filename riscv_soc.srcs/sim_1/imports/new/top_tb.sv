`define SIM
`define ASSERT(CONDITION, MESSAGE) \
   if ((CONDITION) == 1'b1) ; \
   else begin $error($sformatf MESSAGE); end

module top_tb ();
  reg clk = 1;
  always #1 clk = ~clk;
  reg reset;

  integer jumptotal                = 0;
  integer jumppredictedcorrectly   = 0;
  integer branchtotal              = 0;
  integer branchpredictedcorrectly = 0;

  top top (
    .clk   (clk),
    .reset (reset)
  );

  // Raw fetch PC — used for halt detection (j halt keeps PC constant)
  wire [31:0] current_pc = top.riscv.dp.PCF_o;

  // Debug register aliases (rf.sv exposes these under `ifdef SIM)
  wire [31:0] reg_zero = top.riscv.dp.rf.zero;
  wire [31:0] reg_ra   = top.riscv.dp.rf.ra;
  wire [31:0] reg_a0   = top.riscv.dp.rf.a0;

  reg [31:0] prev_pc;
  integer i;

  initial begin
    $display("Begin simulation.");
    reset   = 1;
    prev_pc = 32'hx;
    @(negedge clk);
    @(negedge clk);
    reset = 0;

    for (i = 0; i < 100000; i = i + 1) begin
      @(negedge clk);

      if (top.riscv.dp.BranchE_i)
        branchtotal++;
      if (top.riscv.dp.JumpE_i)
        jumptotal++;
      if (~top.riscv.dp.MisspredictE_o & top.riscv.dp.BranchE_i)
        branchpredictedcorrectly++;
      if (~top.riscv.dp.MisspredictE_o & top.riscv.dp.JumpE_i)
        jumppredictedcorrectly++;

`ifdef TRACE
      if (i < 200) begin
        $display("cyc=%0d PC=%h stF=%b mpE=%b f3E=%h btE=%b brE=%b jeE=%b",
          i, current_pc,
          top.riscv.dp.StallF_i,
          top.riscv.dp.MisspredictE_o,
          top.riscv.dp.funct3E,
          top.riscv.dp.BranchTakenE_o,
          top.riscv.dp.BranchE_i,
          top.riscv.dp.JumpE_i);
      end
`endif

      // Halt detection: fetch PC stopped advancing (j halt reached)
      if (current_pc !== 32'hx && current_pc == prev_pc) begin
        $display("#cycles = %0d", i);
        break;
      end
      prev_pc = current_pc;
    end

    $display("\n=== Final Register Values ===");
    $display("a0 (verify result)  = %0d  (0 = PASS)", reg_a0);

    $display("\n=== Branch/Jump Statistics ===");
    $display("Branches executed      = %0d", branchtotal);
    $display("Branches predicted OK  = %0d", branchpredictedcorrectly);
    $display("Jumps executed         = %0d", jumptotal);
    $display("Jumps predicted OK     = %0d", jumppredictedcorrectly);
    if (branchtotal > 0)
      $display("Branch accuracy        = %0.1f%%",
               (branchpredictedcorrectly * 100.0) / branchtotal);

    $display("End simulation.");
    $finish;
  end
endmodule

`undef ASSERT
