module datapath(
    input wire clk,
    input wire reset,
    output wire [31:0] Adr,
    output wire [31:0] WriteData,
    input wire [31:0] ReadData,
    output wire [31:0] Instr,
    output wire [3:0] ALUFlags,
    input wire PCWrite,
    input wire RegWrite,
    input wire IRWrite,
    input wire AdrSrc,
    input wire [1:0] RegSrc,
    input wire [1:0] ALUSrcA,
    input wire [1:0] ALUSrcB,
    input wire [1:0] ResultSrc,
    input wire [1:0] ImmSrc,
    input wire [2:0] ALUControl,
    input wire PCS
);
    wire [31:0] PCNext;
    wire [31:0] PC;
    wire [31:0] ExtImm;
    wire [31:0] SrcA;
    wire [31:0] SrcB;
    wire [31:0] Result;
    wire [31:0] Data;
    wire [31:0] RD1;
    wire [31:0] RD2;
    wire [31:0] A_reg;
    wire [31:0] ALUResult;
    wire [31:0] ALUOut;
    wire [3:0] RA1;
    wire [3:0] RA2;

    flopenr #(32) pcreg(clk, reset, PCWrite, PCNext, PC);
    mux2 #(32) pcmux(ALUResult, Result, PCS, PCNext);

    mux2 #(32) adrmux(PC, ALUOut, AdrSrc, Adr);
    flopenr #(32) ir(clk, reset, IRWrite, ReadData, Instr);
    flopenr #(32) datareg(clk, reset, 1'b1, ReadData, Data);

    mux2 #(4) ra1mux(Instr[19:16], 4'b1111, RegSrc[0], RA1);
    mux2 #(4) ra2mux(Instr[3:0], Instr[15:12], RegSrc[1], RA2);
    regfile rf(clk, RegWrite, RA1, RA2, Instr[15:12], Result, PC, RD1, RD2);
    flopenr #(32) areg(clk, reset, 1'b1, RD1, A_reg);
    flopenr #(32) breg(clk, reset, 1'b1, RD2, WriteData);

    extend ext(Instr[23:0], ImmSrc, ExtImm);
    mux2 #(32) srcAmux(A_reg, PC, ALUSrcA[0], SrcA);
    mux3 #(32) srcBmux(WriteData, ExtImm, 32'd4, ALUSrcB, SrcB);
    alu alu(SrcA, SrcB, ALUControl, ALUResult, ALUFlags);
    flopr #(32) aluoutreg(clk, reset, ALUResult, ALUOut);

    mux3 #(32) resmux(ALUOut, Data, PC, ResultSrc, Result);
endmodule
