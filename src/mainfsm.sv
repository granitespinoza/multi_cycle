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
                     UNKNOWN  = 10;

    always @(posedge clk or posedge reset)
        if (reset)
            state <= FETCH;
        else
            state <= nextstate;

    always @(*)
        casex (state)
            FETCH:    nextstate = DECODE;
            DECODE:   case (Op)
                        2'b00: nextstate = Funct[5] ? EXECUTEI : EXECUTER;
                        2'b01: nextstate = MEMADR;
                        2'b10: nextstate = BRANCH;
                        default: nextstate = UNKNOWN;
                       endcase
            EXECUTER: nextstate = ALUWB;
            EXECUTEI: nextstate = ALUWB;
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
