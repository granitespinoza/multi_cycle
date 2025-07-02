// Cambios para habilitar multiplicación y división:
// 1. Se amplió ALUControl a 4 bits para codificar nuevas instrucciones.
// 2. Se agregaron UMUL y SMUL para multiplicaciones con y sin signo.
// 3. Se agregó DIV protegido contra división por cero.
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
            4'b0100: Result = a * b;                   // UMUL: multiplicación sin signo
            4'b0101: Result = $signed(a) * $signed(b); // SMUL: multiplicación con signo
            4'b0110: Result = a * b;                   // Reservado para extensiones
            4'b0111: Result = b != 0 ? a / b : 32'hxxxxxxxx; // DIV: división protegida
            default: Result = 32'hxxxxxxxx;
        endcase

    always @(*) begin
        ALUFlags[3] = Result[31];
        ALUFlags[2] = (Result == 32'h00000000);
        ALUFlags[1] = (ALUControl==4'b0000 || ALUControl==4'b0001) ? sum[32] : 1'b0;
        ALUFlags[0] = (ALUControl==4'b0000 || ALUControl==4'b0001) ? (sum[31]^a[31]^b[31]^sum[32]) : 1'b0;
    end
endmodule
