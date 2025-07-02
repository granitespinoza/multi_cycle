`timescale 1ns/1ps

// Archivo unificado para su uso en EDAplayground.
// Se incluyen todos los módulos del procesador multi-ciclo.
// Se añadieron comentarios en español para UMUL, SMUL y DIV
// y una breve explicación del datapath y la tabla de ALUControl.

//---------------------- Top level ----------------------
module top(
    input wire clk,
    input wire reset,
    output wire [31:0] WriteData,
    output wire [31:0] Adr,
    output wire MemWrite
);
    wire [31:0] ReadData;

    arm arm(
        .clk(clk),
        .reset(reset),
        .MemWrite(MemWrite),
        .Adr(Adr),
        .WriteData(WriteData),
        .ReadData(ReadData)
    );

    mem mem(
        .clk(clk),
        .we(MemWrite),
        .a(Adr),
        .wd(WriteData),
        .rd(ReadData)
    );
endmodule

//---------------------- Memoria simple ----------------------
module mem(
    input wire clk,
    input wire we,
    input wire [31:0] a,
    input wire [31:0] wd,
    output wire [31:0] rd
);
    reg [31:0] RAM [0:63];
    initial $readmemh("memfile.dat", RAM);
    assign rd = RAM[a[31:2]]; // alineado a palabra

    always @(posedge clk)
        if (we)
            RAM[a[31:2]] <= wd;
endmodule

//---------------------- Procesador ----------------------
module arm(
    input wire clk,
    input wire reset,
    output wire MemWrite,
    output wire [31:0] Adr,
    output wire [31:0] WriteData,
    input wire [31:0] ReadData
);
    wire [31:0] Instr;
    wire [3:0] ALUFlags;
    wire PCWrite;
    wire RegWrite;
    wire IRWrite;
    wire AdrSrc;
    wire [1:0] RegSrc;
    wire [1:0] ALUSrcA;
    wire [1:0] ALUSrcB;
    wire [1:0] ImmSrc;
    wire [3:0] ALUControl; // ancho ampliado a 4 bits
    wire [1:0] ResultSrc;
    wire PCS;

    controller c(
        .clk(clk),
        .reset(reset),
        .Instr(Instr[31:12]),
        .ALUFlags(ALUFlags),
        .PCWrite(PCWrite),
        .MemWrite(MemWrite),
        .RegWrite(RegWrite),
        .IRWrite(IRWrite),
        .AdrSrc(AdrSrc),
        .RegSrc(RegSrc),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .ResultSrc(ResultSrc),
        .ImmSrc(ImmSrc),
        .ALUControl(ALUControl),
        .PCS(PCS)
    );

    datapath dp(
        .clk(clk),
        .reset(reset),
        .Adr(Adr),
        .WriteData(WriteData),
        .ReadData(ReadData),
        .Instr(Instr),
        .ALUFlags(ALUFlags),
        .PCWrite(PCWrite),
        .RegWrite(RegWrite),
        .IRWrite(IRWrite),
        .AdrSrc(AdrSrc),
        .RegSrc(RegSrc),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .ResultSrc(ResultSrc),
        .ImmSrc(ImmSrc),
        .ALUControl(ALUControl),
        .PCS(PCS)
    );
endmodule

//---------------------- Unidad de Control ----------------------
module controller(
    input wire clk,
    input wire reset,
    input wire [31:12] Instr,
    input wire [3:0] ALUFlags,
    output wire PCWrite,
    output wire MemWrite,
    output wire RegWrite,
    output wire IRWrite,
    output wire AdrSrc,
    output wire [1:0] RegSrc,
    output wire [1:0] ALUSrcA,
    output wire [1:0] ALUSrcB,
    output wire [1:0] ResultSrc,
    output wire [1:0] ImmSrc,
    output wire [3:0] ALUControl,
    output wire PCS
);
    wire [1:0] FlagW;
    wire NextPC;
    wire RegW;
    wire MemW;

    decode dec(
        .clk(clk),
        .reset(reset),
        .Op(Instr[27:26]),
        .Funct(Instr[25:20]),
        .Rd(Instr[15:12]),
        .FlagW(FlagW),
        .PCS(PCS),
        .NextPC(NextPC),
        .RegW(RegW),
        .MemW(MemW),
        .IRWrite(IRWrite),
        .AdrSrc(AdrSrc),
        .ResultSrc(ResultSrc),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .ImmSrc(ImmSrc),
        .RegSrc(RegSrc),
        .ALUControl(ALUControl)
    );

    condlogic cl(
        .clk(clk),
        .reset(reset),
        .Cond(Instr[31:28]),
        .ALUFlags(ALUFlags),
        .FlagW(FlagW),
        .PCS(PCS),
        .NextPC(NextPC),
        .RegW(RegW),
        .MemW(MemW),
        .PCWrite(PCWrite),
        .RegWrite(RegWrite),
        .MemWrite(MemWrite)
    );
endmodule

//---------------------- Decodificador ----------------------
// Tabla de ALUControl:
// 0000 -> ADD
// 0001 -> SUB
// 0010 -> AND
// 0011 -> ORR
// 0100 -> UMUL (sin signo)
// 0101 -> SMUL (con signo)
// 0110 -> Reservado
// 0111 -> DIV
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
                                 Funct[4:1] == 4'b0001 ? 4'b0100 : // UMUL
                                 Funct[4:1] == 4'b1000 ? 4'b0101 : // SMUL
                                 Funct[4:1] == 4'b1001 ? 4'b0110 :
                                 Funct[4:1] == 4'b1010 ? 4'b0111 : // DIV
                                 4'bxxxx) : 4'b0000;

    assign FlagW[1] = ALUOp & Funct[0];
    assign FlagW[0] = ALUOp & Funct[0] & (ALUControl == 4'b0000 || ALUControl == 4'b0001);

    assign PCS = Branch | (RegW & (Rd == 4'b1111));
    assign ImmSrc = Op;
    assign RegSrc[0] = (Op == 2'b10);
    assign RegSrc[1] = (Op == 2'b01) & ~Funct[0];
endmodule

//---------------------- FSM principal ----------------------
module mainfsm(
    input wire clk,
    input wire reset,
    input wire [1:0] Op,
    input wire [5:0] Funct,
    output wire IRWrite,
    output wire AdrSrc,
    output wire [1:0] ALUSrcA,
    output wire [1:0] ALUSrcB,
    output wire [1:0] ResultSrc,
    output wire NextPC,
    output wire RegW,
    output wire MemW,
    output wire Branch,
    output wire ALUOp
);
    reg [3:0] state;
    reg [3:0] nextstate;
    reg [12:0] controls;

    localparam [3:0] FETCH    = 0,
                     DECODE   = 1,
                     MEMADR   = 2,
                     MEMRD    = 3,
                     MEMWB    = 4,
                     MEMWR    = 5,
                     EXECUTER = 6,
                     EXECUTEI = 7,
                     ALUWB    = 8,
                     BRANCH   = 9,
                     UNKNOWN  = 10,
                     DIV1     = 11, // DIV etapa 1
                     DIV2     = 12; // DIV etapa 2

    always @(posedge clk or posedge reset)
        if (reset)
            state <= FETCH;
        else
            state <= nextstate;

    always @(*)
        casex (state)
            FETCH:    nextstate = DECODE;
            DECODE:   case (Op)
                        2'b00: begin
                            if (Funct[5])
                                nextstate = EXECUTEI;
                            else if (Funct[4:1] == 4'b1010)
                                nextstate = DIV1; // Detecta DIV
                            else
                                nextstate = EXECUTER;
                        end
                        2'b01: nextstate = MEMADR;
                        2'b10: nextstate = BRANCH;
                        default: nextstate = UNKNOWN;
                       endcase
            EXECUTER: nextstate = ALUWB;
            EXECUTEI: nextstate = ALUWB;
            DIV1:     nextstate = DIV2; // paso 1
            DIV2:     nextstate = ALUWB; // paso 2
            MEMADR:   nextstate = Funct[0] ? MEMRD : MEMWR;
            MEMRD:    nextstate = MEMWB;
            MEMWR:    nextstate = FETCH;
            MEMWB:    nextstate = FETCH;
            ALUWB:    nextstate = FETCH;
            BRANCH:   nextstate = FETCH;
            default:  nextstate = FETCH;
        endcase

    always @(*)
        case (state)
            FETCH:    controls = 13'b1000100001100;
            DECODE:   controls = 13'b0000001001100;
            EXECUTER: controls = 13'b0000000000001;
            EXECUTEI: controls = 13'b0000000000101;
            DIV1:     controls = 13'b0000000000001; // Señales DIV paso 1
            DIV2:     controls = 13'b0000000000001; // Señales DIV paso 2
            ALUWB:    controls = 13'b0001000000000;
            MEMADR:   controls = 13'b0000000000100;
            MEMWR:    controls = 13'b0010010000000;
            MEMRD:    controls = 13'b0000010000000;
            MEMWB:    controls = 13'b0001000100000;
            BRANCH:   controls = 13'b0100000000100;
            default:  controls = 13'bxxxxxxxxxxxxx;
        endcase

    assign {NextPC, Branch, MemW, RegW, IRWrite, AdrSrc, ResultSrc, ALUSrcA, ALUSrcB, ALUOp} = controls;
endmodule

//---------------------- Lógica de Condición ----------------------
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

//---------------------- Verificación de Condición ----------------------
module condcheck(
    input wire [3:0] Cond,
    input wire [3:0] Flags,
    output wire CondEx
);
    reg N,Z,C,V;
    always @(*) {N,Z,C,V} = Flags;

    reg [15:0] CondExLut;
    always @(*)
        case ({N,Z,C,V})
            4'b0000: CondExLut = 16'b1111100011010101;
            4'b0001: CondExLut = 16'b1110100111100100;
            4'b0010: CondExLut = 16'b1111110010010111;
            4'b0011: CondExLut = 16'b1110110110100100;
            4'b0100: CondExLut = 16'b1111101011011101;
            4'b0101: CondExLut = 16'b1110101111101100;
            4'b0110: CondExLut = 16'b1111111010011111;
            4'b0111: CondExLut = 16'b1110111110101100;
            4'b1000: CondExLut = 16'b1111100011010101;
            4'b1001: CondExLut = 16'b1110100111100100;
            4'b1010: CondExLut = 16'b1111110010010111;
            4'b1011: CondExLut = 16'b1110110110100100;
            4'b1100: CondExLut = 16'b1111101011011101;
            4'b1101: CondExLut = 16'b1110101111101100;
            4'b1110: CondExLut = 16'b1111111010011111;
            4'b1111: CondExLut = 16'b1110111110101100;
            default: CondExLut = 16'b1111100011010101;
        endcase

    assign CondEx = CondExLut[Cond];
endmodule

//---------------------- Datapath ----------------------
// Este módulo conecta PC, registro de instrucciones, ALU y memoria.
// Mediante multiplexores controla el flujo de datos para ejecutar
// UMUL, SMUL y DIV además de las instrucciones básicas.
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
    input wire [3:0] ALUControl,
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

    // Camino de datos principal
    flopenr #(32) pcreg(clk, reset, PCWrite, PCNext, PC);
    mux2 #(32) pcmux(ALUResult, Result, PCS, PCNext); // selecciona nuevo PC

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

//---------------------- Banco de Registros ----------------------
module regfile(
    input wire clk,
    input wire we3,
    input wire [3:0] ra1,
    input wire [3:0] ra2,
    input wire [3:0] wa3,
    input wire [31:0] wd3,
    input wire [31:0] r15,
    output wire [31:0] rd1,
    output wire [31:0] rd2
);
    reg [31:0] rf [14:0];

    always @(posedge clk)
        if (we3 && (wa3 != 4'b1111))
            rf[wa3] <= wd3;

    assign rd1 = (ra1 == 4'b1111) ? r15 : rf[ra1];
    assign rd2 = (ra2 == 4'b1111) ? r15 : rf[ra2];
endmodule

//---------------------- Extensor de Inmediatos ----------------------
module extend(
    input wire [23:0] Instr,
    input wire [1:0] ImmSrc,
    output reg [31:0] ExtImm
);
    always @(*)
        case (ImmSrc)
            2'b00: ExtImm = {{24{1'b0}}, Instr[7:0]};
            2'b01: ExtImm = {{20{1'b0}}, Instr[11:0]};
            2'b10: ExtImm = {{6{Instr[23]}}, Instr[23:0], 2'b00};
            default: ExtImm = 32'hxxxxxxxx;
        endcase
endmodule

//---------------------- ALU ----------------------
// UMUL, SMUL y DIV implementados aquí.
module alu(
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [3:0] ALUControl,
    output reg [31:0] Result,
    output reg [3:0] ALUFlags
);
    wire [32:0] sum = {a[31], a} + {b[31], b};

    always @(*)
        case (ALUControl)
            4'b0000: Result = a + b;
            4'b0001: Result = a - b;
            4'b0010: Result = a & b;
            4'b0011: Result = a | b;
            4'b0100: Result = a * b;                   // UMUL
            4'b0101: Result = $signed(a) * $signed(b); // SMUL
            4'b0110: Result = a * b;                   // Reservado
            4'b0111: Result = b != 0 ? a / b : 32'hxxxxxxxx; // DIV protegido
            default: Result = 32'hxxxxxxxx;
        endcase

    always @(*) begin
        ALUFlags[3] = Result[31];
        ALUFlags[2] = (Result == 32'h00000000);
        ALUFlags[1] = (ALUControl==4'b0000 || ALUControl==4'b0001) ? sum[32] : 1'b0;
        ALUFlags[0] = (ALUControl==4'b0000 || ALUControl==4'b0001) ? (sum[31]^a[31]^b[31]^sum[32]) : 1'b0;
    end
endmodule

//---------------------- Bloques genéricos ----------------------
module flopr #(parameter WIDTH = 8)(
    input wire clk,
    input wire reset,
    input wire [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);
    always @(posedge clk or posedge reset)
        if (reset)
            q <= 0;
        else
            q <= d;
endmodule

module flopenr #(parameter WIDTH = 8)(
    input wire clk,
    input wire reset,
    input wire en,
    input wire [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);
    always @(posedge clk or posedge reset)
        if (reset)
            q <= 0;
        else if (en)
            q <= d;
endmodule

module mux2 #(parameter WIDTH = 8)(
    input wire [WIDTH-1:0] d0,
    input wire [WIDTH-1:0] d1,
    input wire s,
    output wire [WIDTH-1:0] y
);
    assign y = s ? d1 : d0;
endmodule

module mux3 #(parameter WIDTH = 8)(
    input wire [WIDTH-1:0] d0,
    input wire [WIDTH-1:0] d1,
    input wire [WIDTH-1:0] d2,
    input wire [1:0] s,
    output wire [WIDTH-1:0] y
);
    assign y = (s[1] ? d2 : (s[0] ? d1 : d0));
endmodule

