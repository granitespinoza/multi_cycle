module condlogic(
    input wire clk,
    input wire reset,
    input wire [3:0] Cond,
    input wire [3:0] ALUFlags,
    input wire [1:0] FlagW,
    input wire PCS,
    input wire NextPC,
    input wire RegW,
    input wire MemW,
    output wire PCWrite,
    output wire RegWrite,
    output wire MemWrite
);
    wire [1:0] FlagWrite;
    wire [3:0] Flags;
    wire CondEx;

    flopr #(2) flagwritereg(clk, reset, FlagW & {2{CondEx}}, FlagWrite);
    flopenr #(4) flagsreg(clk, reset, |FlagWrite, ALUFlags, Flags);
    condcheck cc(Cond, Flags, CondEx);

    assign PCWrite = NextPC | (CondEx & PCS);
    assign RegWrite = CondEx & RegW;
    assign MemWrite = CondEx & MemW;
endmodule
