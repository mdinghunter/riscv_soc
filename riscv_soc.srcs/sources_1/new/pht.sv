module pht #(
  parameter int unsigned NUM_GHR_BITS = 3
) (
  input                        clk,
  input                        reset_i,
  input  [NUM_GHR_BITS-1:0]   PHTreadaddress_o,
  input                        PHTincrement_i,
  input                        B_i,
  output wire                  predict_taken
);

  localparam int unsigned NumPhtEntries = 2 ** NUM_GHR_BITS;

  reg [1:0]              PHT              [NumPhtEntries];
  reg [NUM_GHR_BITS-1:0] PHTwriteaddress_d;
  reg [NUM_GHR_BITS-1:0] PHTwriteaddress_e;
  integer i;

  always @(posedge clk or posedge reset_i) begin
    if (reset_i) begin
      for (i = 0; i < NumPhtEntries; i = i + 1)
        PHT[i] <= 2'b00;
    end else begin
      if (B_i) begin
        case (PHTincrement_i)
          1'b0: if (PHT[PHTwriteaddress_e] != 2'b00)
                  PHT[PHTwriteaddress_e] <= PHT[PHTwriteaddress_e] - 1;
          1'b1: if (PHT[PHTwriteaddress_e] != 2'b11)
                  PHT[PHTwriteaddress_e] <= PHT[PHTwriteaddress_e] + 1;
          default: ;
        endcase
      end
    end
  end

  always @(posedge clk or posedge reset_i) begin
    if (reset_i) begin
      PHTwriteaddress_d <= '0;
      PHTwriteaddress_e <= '0;
    end else begin
      PHTwriteaddress_d <= PHTreadaddress_o;
      PHTwriteaddress_e <= PHTwriteaddress_d;
    end
  end

  assign predict_taken = PHT[PHTreadaddress_o][1];

endmodule
