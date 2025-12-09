`timescale 1ns/1ps

module ex_mem_reg #(parameter WIDTH = 32) (
    input  logic              clk,
    input  logic              rst,
    input  logic              en,
    input  logic              flush,
    input  logic [WIDTH-1:0]  pc4_ex,
    input  logic [WIDTH-1:0]  pcimm_ex,
    input  logic [WIDTH-1:0]  alu_out_ex,
    input  logic [WIDTH-1:0]  rs2_data_ex,
    input  logic [4:0]        rd_ex,
    input  logic [1:0]        wb_mux_sel_ex,
    input  logic              reg_file_wr_ex,
    input  logic              mem_read_ex,
    input  logic              mem_write_ex,
    input  logic              one_byte_ex,
    input  logic              two_bytes_ex,
    input  logic              four_bytes_ex,
    output logic [WIDTH-1:0]  pc4_mem,
    output logic [WIDTH-1:0]  pcimm_mem,
    output logic [WIDTH-1:0]  alu_out_mem,
    output logic [WIDTH-1:0]  rs2_data_mem,
    output logic [4:0]        rd_mem,
    output logic [1:0]        wb_mux_sel_mem,
    output logic              reg_file_wr_mem,
    output logic              mem_read_mem,
    output logic              mem_write_mem,
    output logic              one_byte_mem,
    output logic              two_bytes_mem,
    output logic              four_bytes_mem
);
  always_ff @(posedge clk or posedge rst) begin
    if (rst || flush) begin
      pc4_mem         <= '0;
      pcimm_mem       <= '0;
      alu_out_mem     <= '0;
      rs2_data_mem    <= '0;
      rd_mem          <= '0;
      wb_mux_sel_mem  <= 2'd0;
      reg_file_wr_mem <= 1'b0;
      mem_read_mem    <= 1'b0;
      mem_write_mem   <= 1'b0;
      one_byte_mem    <= 1'b0;
      two_bytes_mem   <= 1'b0;
      four_bytes_mem  <= 1'b0;
    end else if (en) begin
      pc4_mem         <= pc4_ex;
      pcimm_mem       <= pcimm_ex;
      alu_out_mem     <= alu_out_ex;
      rs2_data_mem    <= rs2_data_ex;
      rd_mem          <= rd_ex;
      wb_mux_sel_mem  <= wb_mux_sel_ex;
      reg_file_wr_mem <= reg_file_wr_ex;
      mem_read_mem    <= mem_read_ex;
      mem_write_mem   <= mem_write_ex;
      one_byte_mem    <= one_byte_ex;
      two_bytes_mem   <= two_bytes_ex;
      four_bytes_mem  <= four_bytes_ex;
    end
  end
endmodule
