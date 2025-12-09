`timescale 1ns/1ps

module mem_wb_reg #(parameter WIDTH = 32) (
    input  logic              clk,
    input  logic              rst,
    input  logic              en,
    input  logic              flush,
    input  logic [WIDTH-1:0]  mem_data_mem,
    input  logic [WIDTH-1:0]  alu_out_mem,
    input  logic [WIDTH-1:0]  pc4_mem,
    input  logic [WIDTH-1:0]  pcimm_mem,
    input  logic [4:0]        rd_mem,
    input  logic [1:0]        wb_mux_sel_mem,
    input  logic              reg_file_wr_mem,
    output logic [WIDTH-1:0]  mem_data_wb,
    output logic [WIDTH-1:0]  alu_out_wb,
    output logic [WIDTH-1:0]  pc4_wb,
    output logic [WIDTH-1:0]  pcimm_wb,
    output logic [4:0]        rd_wb,
    output logic [1:0]        wb_mux_sel_wb,
    output logic              reg_file_wr_wb
);
  always_ff @(posedge clk or posedge rst) begin
    if (rst || flush) begin
      mem_data_wb     <= '0;
      alu_out_wb      <= '0;
      pc4_wb          <= '0;
      pcimm_wb        <= '0;
      rd_wb           <= '0;
      wb_mux_sel_wb   <= 2'd0;
      reg_file_wr_wb  <= 1'b0;
    end else if (en) begin
      mem_data_wb     <= mem_data_mem;
      alu_out_wb      <= alu_out_mem;
      pc4_wb          <= pc4_mem;
      pcimm_wb        <= pcimm_mem;
      rd_wb           <= rd_mem;
      wb_mux_sel_wb   <= wb_mux_sel_mem;
      reg_file_wr_wb  <= reg_file_wr_mem;
    end
  end
endmodule
