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
