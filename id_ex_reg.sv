`timescale 1ns/1ps

module id_ex_reg #(parameter WIDTH = 32) (
    input  logic              clk,
    input  logic              rst,
    input  logic              en,
    input  logic              flush,
    input  logic [WIDTH-1:0]  pc_id,
    input  logic [WIDTH-1:0]  rs1_data_id,
    input  logic [WIDTH-1:0]  rs2_data_id,
    input  logic [WIDTH-1:0]  imm_id,
    input  logic [WIDTH-1:0]  instr_id,
    output logic [WIDTH-1:0]  pc_ex,
    output logic [WIDTH-1:0]  rs1_data_ex,
    output logic [WIDTH-1:0]  rs2_data_ex,
    output logic [WIDTH-1:0]  imm_ex,
    output logic [WIDTH-1:0]  instr_ex
);
  always_ff @(posedge clk or posedge rst) begin
    if (rst || flush) begin
      pc_ex       <= '0;
      rs1_data_ex <= '0;
      rs2_data_ex <= '0;
      imm_ex      <= '0;
      instr_ex    <= 32'h00000013;
    end else if (en) begin
      pc_ex       <= pc_id;
      rs1_data_ex <= rs1_data_id;
      rs2_data_ex <= rs2_data_id;
      imm_ex      <= imm_id;
      instr_ex    <= instr_id;
    end
  end
endmodule
