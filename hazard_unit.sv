`timescale 1ns/1ps

module hazard_unit (
    // --- ID stage ---
    input  logic [4:0] rs1_id,
    input  logic [4:0] rs2_id,

    // --- EX stage ---
    input  logic        mem_read_ex,
    input  logic [4:0]  rd_ex,

    // --- Branch/JAL/JALR decision (desde EX) ---
    input  logic [1:0]  if_mux_sel_ex,

    // --- Salidas ---
    output logic pc_en,
    output logic if_id_en,
    output logic if_id_flush,
    output logic id_ex_flush
);

  // 1) LOAD–USE HAZARD → stall 1 ciclo
  logic load_use_hazard;
  assign load_use_hazard =
      mem_read_ex &&
      (rd_ex != 5'd0) &&
      ( (rd_ex == rs1_id) || (rd_ex == rs2_id) );

  // 2) FLUSH por salto/branch tomado
  logic flush_branch;
  assign flush_branch = (if_mux_sel_ex == 2'd1) || (if_mux_sel_ex == 2'd2);

  // Señales finales
  assign pc_en       = !load_use_hazard;
  assign if_id_en    = !load_use_hazard;
  assign id_ex_flush = load_use_hazard;

  // El flush de branch SOLO limpia IF/ID (no ID/EX)
  assign if_id_flush = flush_branch;

endmodule
