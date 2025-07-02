module decode(
    input wire clk,
    input wire reset,
    input wire [1:0] Op,
    input wire [5:0] Funct,
    input wire [3:0] Rd,
    output wire [1:0] FlagW,
    output wire PCS,
    output wire NextPC,
    output wire RegW,
    output wire MemW,
    output wire IRWrite,
    output wire AdrSrc,
    output wire [1:0] ResultSrc,
    output wire [1:0] ALUSrcA,
    output wire [1:0] ALUSrcB,
    output wire [1:0] ImmSrc,
    output wire [1:0] RegSrc,
    output wire [3:0] ALUControl
);
    wire Branch;
    wire ALUOp;

    mainfsm fsm(
        .clk(clk),
        .reset(reset),
        .Op(Op),
        .Funct(Funct),
        .IRWrite(IRWrite),
        .AdrSrc(AdrSrc),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .ResultSrc(ResultSrc),
        .NextPC(NextPC),
        .RegW(RegW),
        .MemW(MemW),
        .Branch(Branch),
        .ALUOp(ALUOp)
    );

    assign ALUControl = ALUOp ? (Funct[4:1] == 4'b0100 ? 4'b0000 :
                                 Funct[4:1] == 4'b0010 ? 4'b0001 :
                                 Funct[4:1] == 4'b0000 ? 4'b0010 :
                                 Funct[4:1] == 4'b1100 ? 4'b0011 :
                                 Funct[4:1] == 4'b0001 ? 4'b0100 :
                                 Funct[4:1] == 4'b1000 ? 4'b0101 :
                                 Funct[4:1] == 4'b1001 ? 4'b0110 :
                                 Funct[4:1] == 4'b1010 ? 4'b0111 :
                                 4'bxxxx) : 4'b0000;

    assign FlagW[1] = ALUOp & Funct[0];
    assign FlagW[0] = ALUOp & Funct[0] & (ALUControl == 4'b0000 || ALUControl == 4'b0001);

    assign PCS = Branch | (RegW & (Rd == 4'b1111));
    assign ImmSrc = Op;
    assign RegSrc[0] = (Op == 2'b10);
    assign RegSrc[1] = (Op == 2'b01) & ~Funct[0];
endmodule
