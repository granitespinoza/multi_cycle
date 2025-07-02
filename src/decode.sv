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
    output wire [2:0] ALUControl
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

    assign ALUControl = ALUOp ? (Funct[4:1] == 4'b0100 ? 3'b000 :
                                 Funct[4:1] == 4'b0010 ? 3'b001 :
                                 Funct[4:1] == 4'b0000 ? 3'b010 :
                                 Funct[4:1] == 4'b1100 ? 3'b011 :
                                 Funct[4:1] == 4'b0001 ? 3'b100 :
                                 3'bxxx) : 3'b000;

    assign FlagW[1] = ALUOp & Funct[0];
    assign FlagW[0] = ALUOp & Funct[0] & (ALUControl == 3'b000 || ALUControl == 3'b001);

    assign PCS = Branch | (RegW & (Rd == 4'b1111));
    assign ImmSrc = Op;
    assign RegSrc[0] = (Op == 2'b10);
    assign RegSrc[1] = (Op == 2'b01) & ~Funct[0];
endmodule
