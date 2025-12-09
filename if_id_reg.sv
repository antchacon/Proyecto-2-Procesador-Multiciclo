`timescale 1ns/1ps

module if_id_reg #(parameter WIDTH = 32) (
    input  logic              clk,
    input  logic              rst,
    input  logic              en,
    input  logic              flush,
    input  logic [WIDTH-1:0]  pc_if,
    input  logic [WIDTH-1:0]  instr_if,
    output logic [WIDTH-1:0]  pc_id,
    output logic [WIDTH-1:0]  instr_id
);
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      pc_id    <= '0;
      instr_id <= 32'h00000013; // NOP
    end else if (flush) begin
      pc_id    <= '0;
      instr_id <= 32'h00000013;
    end else if (en) begin
      pc_id    <= pc_if;
      instr_id <= instr_if;
    end
  end
endmodule
