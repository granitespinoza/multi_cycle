module alu(
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [2:0] ALUControl,
    output reg [31:0] Result,
    output reg [3:0] ALUFlags
);
    wire [32:0] sum = {a[31], a} + {b[31], b};
    wire [32:0] diff = {a[31], a} + {~b[31], ~b} + 1'b1;

    always @(*)
        case (ALUControl)
            3'b000: Result = a + b;
            3'b001: Result = a - b;
            3'b010: Result = a & b;
            3'b011: Result = a | b;
            3'b100: Result = a * b;
            default: Result = 32'hxxxxxxxx;
        endcase

    always @(*) begin
        ALUFlags[3] = Result[31];
        ALUFlags[2] = (Result == 32'h00000000);
        case (ALUControl)
            3'b000: begin
                ALUFlags[1] = sum[32];
                ALUFlags[0] = sum[31] ^ a[31] ^ b[31] ^ sum[32];
            end
            3'b001: begin
                ALUFlags[1] = diff[32];
                ALUFlags[0] = diff[31] ^ a[31] ^ ~b[31] ^ diff[32];
            end
            default: begin
                ALUFlags[1] = 1'b0;
                ALUFlags[0] = 1'b0;
            end
        endcase
    end
endmodule
