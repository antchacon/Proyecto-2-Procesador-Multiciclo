`define  MULTICYCLE

`include "mux_2_1.sv"
`include "mux_4_1.sv"
`include "adder.sv"
`include "register.sv"
`include "reg_file.sv"
`include "alu.sv"
`include "data_mem.sv"
`include "inst_mem.sv"
`include "imm_gen.sv"
`include "control_deco.sv"
`include "if_id_reg.sv"
`include "id_ex_reg.sv"
`include "hazard_unit.sv"
`include "ex_mem_reg.sv"
`include "mem_wb_reg.sv"

`timescale 1ns/1ps

module top #(
  parameter WIDTH           = 32,
  parameter INST_MEM_DEPTH  = 8,
  parameter REG_FILE_DEPTH  = 5,
  parameter DATA_MEM_DEPTH  = 16,
  parameter INST_SIZE       = 32
)(
  input  logic              clk_i,
  input  logic              rst_i,

  output logic [31:0]       ProgAddress_o,
  input  logic [31:0]       ProgIn_i,        // no usado (ROM interna)

  output logic [31:0]       DataAddress_o,
  output logic [31:0]       DataOut_o,
  input  logic [31:0]       DataIn_i,        // no usado (RAM interna)

  output logic              we_o,
  output logic [WIDTH-1:0]  pc_out
);

  // ========= Constantes de opcodes para lógica interna =========
  localparam ALI_OP    = 7'b0010011;
  localparam AL_OP     = 7'b0110011;
  localparam MEM_WR_OP = 7'b0100011;
  localparam MEM_RD_OP = 7'b0000011;
  localparam BR_OP     = 7'b1100011;
  localparam JALR      = 7'b1100111;
  localparam JAL       = 7'b1101111;
  localparam LUI       = 7'b0110111;
  localparam AUIPC     = 7'b0010111;

  // ------------------------------------------------------------
  // Señales de hazards
  // ------------------------------------------------------------
  logic pc_en;
  logic if_id_en;
  logic if_id_flush;
  logic id_ex_flush;

  // ------------------------------------------------------------
  // IF stage
  // ------------------------------------------------------------
  logic [WIDTH-1:0] pc_next;
  logic [WIDTH-1:0] pc_4_if;
  logic [WIDTH-1:0] instr_if;

  register #(.WIDTH(WIDTH)) u_pc (
    .clk     (clk_i),
    .rst     (rst_i),
    .data_in (pc_next),
    .wr      (pc_en),
    .data_out(pc_out)
  );

  adder #(.WIDTH(WIDTH)) u_pc_plus4_if (
    .A   (pc_out),
    .B   (32'd4),
    .out (pc_4_if)
  );

  inst_mem #(.WIDTH(WIDTH), .DEPTH(INST_MEM_DEPTH)) u_rom (
`ifdef MULTICYCLE
    .clk      (clk_i),
`endif
    .rst      (rst_i),
    .data_in  (32'b0),
    .addr     (pc_out[INST_MEM_DEPTH-1:0]),
    .wr       (1'b1),
    .rd       (1'b1),
    .data_out (instr_if)
  );

  // ------------------------------------------------------------
  // IF/ID
  // ------------------------------------------------------------
  logic [WIDTH-1:0] pc_id;
  logic [WIDTH-1:0] instr_id;     // esta es la "instruction" visible al TB

  if_id_reg #(.WIDTH(WIDTH)) u_if_id (
    .clk      (clk_i),
    .rst      (rst_i),
    .en       (if_id_en),
    .flush    (if_id_flush),
    .pc_if    (pc_out),
    .instr_if (instr_if),
    .pc_id    (pc_id),
    .instr_id (instr_id)
  );

  // ------------------------------------------------------------
  // ID stage
  // ------------------------------------------------------------
  logic [4:0] rs1_idx_id, rs2_idx_id, rd_idx_id;
  assign rs1_idx_id = instr_id[19:15];
  assign rs2_idx_id = instr_id[24:20];
  assign rd_idx_id  = instr_id[11:7];

  logic [WIDTH-1:0] rs1_data_id, rs2_data_id;
  logic [WIDTH-1:0] imm_id;

  // WB signals (desde la etapa WB)
  logic [WIDTH-1:0] wb_data;
  logic [4:0]       rd_idx_wb;
  logic             reg_file_wr_wb;

  reg_file #(.WIDTH(WIDTH), .DEPTH(REG_FILE_DEPTH)) u_rf (
    .clk              (clk_i),
    .rst              (rst_i),
    .write_data       (wb_data),
    .write_register   (rd_idx_wb),
    .wr               (reg_file_wr_wb),
    .read_register_1  (rs1_idx_id),
    .read_register_2  (rs2_idx_id),
    .rd               (1'b1),
    .read_data_1      (rs1_data_id),
    .read_data_2      (rs2_data_id)
  );

  imm_gen #(.WIDTH(WIDTH)) u_imm (
    .instr    (instr_id),
    .data_out (imm_id)
  );

  // ------------------------------------------------------------
  // ID/EX
  // ------------------------------------------------------------
  logic [WIDTH-1:0] pc_ex;
  logic [WIDTH-1:0] rs1_data_ex, rs2_data_ex, imm_ex, instr_ex;

  id_ex_reg #(.WIDTH(WIDTH)) u_id_ex (
    .clk        (clk_i),
    .rst        (rst_i),
    .en         (1'b1),
    .flush      (id_ex_flush),
    .pc_id      (pc_id),
    .rs1_data_id(rs1_data_id),
    .rs2_data_id(rs2_data_id),
    .imm_id     (imm_id),
    .instr_id   (instr_id),
    .pc_ex      (pc_ex),
    .rs1_data_ex(rs1_data_ex),
    .rs2_data_ex(rs2_data_ex),
    .imm_ex     (imm_ex),
    .instr_ex   (instr_ex)
  );

  // Índices en EX (para forwarding y hazards)
  logic [4:0] rs1_idx_ex, rs2_idx_ex, rd_idx_ex;
  assign rs1_idx_ex = instr_ex[19:15];
  assign rs2_idx_ex = instr_ex[24:20];
  assign rd_idx_ex  = instr_ex[11:7];

  // ------------------------------------------------------------
  // Señales de MEM y WB (para forwarding)
  // ------------------------------------------------------------
  logic [WIDTH-1:0] pc4_mem, pcimm_mem;
  logic [WIDTH-1:0] alu_out_mem, rs2_data_mem;
  logic [4:0]       rd_idx_mem;
  logic [1:0]       wb_mux_sel_mem;
  logic             reg_file_wr_mem;
  logic             mem_read_mem, mem_write_mem;
  logic             one_byte_mem, two_bytes_mem, four_bytes_mem;

  logic [WIDTH-1:0] mem_data_mem;

  logic [WIDTH-1:0] mem_data_wb, alu_out_wb, pc4_wb, pcimm_wb;
  logic [1:0]       wb_mux_sel_wb;

  // ------------------------------------------------------------
  // EX stage (con FORWARDING)
  // ------------------------------------------------------------
  logic [2:0] func3_ex;
  logic [6:0] func7_ex, opcode_ex;
  assign func3_ex  = instr_ex[14:12];
  assign func7_ex  = instr_ex[31:25];
  assign opcode_ex = instr_ex[6:0];

  // ex_mux_sel se calcula localmente (sin bucle con control_deco)
  logic ex_mux_sel_ex;
  always_comb begin
    case (opcode_ex)
      AL_OP:     ex_mux_sel_ex = 1'b0;  // R-type usa rs2
      ALI_OP,
      MEM_RD_OP,
      MEM_WR_OP,
      JALR,
      LUI,
      AUIPC:     ex_mux_sel_ex = 1'b1;  // usa imm
      default:   ex_mux_sel_ex = 1'b0;
    endcase
  end

  // -------- Forwarding unit --------
  typedef enum logic [1:0] {FWD_NONE=2'b00, FWD_MEM=2'b01, FWD_WB=2'b10} fwd_t;
  fwd_t forwardA, forwardB;

  always_comb begin
    forwardA = FWD_NONE;
    forwardB = FWD_NONE;

    // A: rs1_ex
    if (reg_file_wr_mem && (rd_idx_mem != 0) && (rd_idx_mem == rs1_idx_ex))
      forwardA = FWD_MEM;
    else if (reg_file_wr_wb && (rd_idx_wb != 0) && (rd_idx_wb == rs1_idx_ex))
      forwardA = FWD_WB;

    // B: rs2_ex
    if (reg_file_wr_mem && (rd_idx_mem != 0) && (rd_idx_mem == rs2_idx_ex))
      forwardB = FWD_MEM;
    else if (reg_file_wr_wb && (rd_idx_wb != 0) && (rd_idx_wb == rs2_idx_ex))
      forwardB = FWD_WB;
  end

  logic [WIDTH-1:0] fwd_rs1_ex, fwd_rs2_ex;

  always_comb begin
    // rs1
    case (forwardA)
      FWD_NONE: fwd_rs1_ex = rs1_data_ex;
      FWD_MEM:  fwd_rs1_ex = alu_out_mem; // resultado en MEM
      FWD_WB:   fwd_rs1_ex = wb_data;     // dato final en WB
      default:  fwd_rs1_ex = rs1_data_ex;
    endcase

    // rs2 (para ALU y para stores)
    case (forwardB)
      FWD_NONE: fwd_rs2_ex = rs2_data_ex;
      FWD_MEM:  fwd_rs2_ex = alu_out_mem;
      FWD_WB:   fwd_rs2_ex = wb_data;
      default:  fwd_rs2_ex = rs2_data_ex;
    endcase
  end

  // Entrada B de la ALU: o inmediato o rs2 con forwarding
  logic [WIDTH-1:0] alu_b_in_ex;
  assign alu_b_in_ex = ex_mux_sel_ex ? imm_ex : fwd_rs2_ex;

  logic [WIDTH-1:0] alu_out_ex;
  logic             zero_ex;
  logic             comparison_ex;

  alu #(.WIDTH(WIDTH)) u_alu (
    .data_in_1  (fwd_rs1_ex),
    .data_in_2  (alu_b_in_ex),
    .func3      (func3_ex),
    .func7      (func7_ex),
    .opcode     (opcode_ex),
    .data_out   (alu_out_ex),
    .zero       (zero_ex),
    .comparison (comparison_ex)
  );

  // PC+4 y PC+IMM en EX
  logic [WIDTH-1:0] pc4_ex, pcimm_ex;
  adder #(.WIDTH(WIDTH)) u_pc_plus4_ex (
    .A   (pc_ex),
    .B   (32'd4),
    .out (pc4_ex)
  );

  adder #(.WIDTH(WIDTH)) u_pc_plus_imm_ex (
    .A   (pc_ex),
    .B   (imm_ex),
    .out (pcimm_ex)
  );

  logic [WIDTH-1:0] jalr_target_ex;
  assign jalr_target_ex = alu_out_ex & ~32'd1;

  
  logic [1:0] if_mux_sel_ex;
  logic       ex_mux_sel_dummy;
  logic [1:0] wb_mux_sel_ex;
  logic       reg_file_wr_ex;
  logic       mem_read_ex, mem_write_ex;
  logic       one_byte_ex, two_bytes_ex, four_bytes_ex;
  logic       reg_file_rd_dummy;

  control_deco #(.INST_SIZE(INST_SIZE)) u_ctrl (
    .instr       (instr_ex),
    .comparison  (comparison_ex),
    .if_mux_sel  (if_mux_sel_ex),
    .ex_mux_sel  (ex_mux_sel_dummy),
    .wb_mux_sel  (wb_mux_sel_ex),
    .reg_file_rd (reg_file_rd_dummy),
    .reg_file_wr (reg_file_wr_ex),
    .mem_read    (mem_read_ex),
    .mem_write   (mem_write_ex),
    .one_byte    (one_byte_ex),
    .two_bytes   (two_bytes_ex),
    .four_bytes  (four_bytes_ex)
  );

  // -------- Unidad de hazards --------
  hazard_unit u_haz (
    .rs1_id        (rs1_idx_id),
    .rs2_id        (rs2_idx_id),
    .mem_read_ex   (mem_read_ex),
    .rd_ex         (rd_idx_ex),
    .if_mux_sel_ex (if_mux_sel_ex),
    .pc_en         (pc_en),
    .if_id_en      (if_id_en),
    .if_id_flush   (if_id_flush),
    .id_ex_flush   (id_ex_flush)
  );

  // ------------------------------------------------------------
  // EX/MEM  (nota: pasamos rs2 ya adelantado para stores)
  // ------------------------------------------------------------
  ex_mem_reg #(.WIDTH(WIDTH)) u_ex_mem (
    .clk           (clk_i),
    .rst           (rst_i),
    .en            (1'b1),
    .flush         (1'b0),
    .pc4_ex        (pc4_ex),
    .pcimm_ex      (pcimm_ex),
    .alu_out_ex    (alu_out_ex),
    .rs2_data_ex   (fwd_rs2_ex),      // store data con forwarding
    .rd_ex         (rd_idx_ex),
    .wb_mux_sel_ex (wb_mux_sel_ex),
    .reg_file_wr_ex(reg_file_wr_ex),
    .mem_read_ex   (mem_read_ex),
    .mem_write_ex  (mem_write_ex),
    .one_byte_ex   (one_byte_ex),
    .two_bytes_ex  (two_bytes_ex),
    .four_bytes_ex (four_bytes_ex),
    .pc4_mem       (pc4_mem),
    .pcimm_mem     (pcimm_mem),
    .alu_out_mem   (alu_out_mem),
    .rs2_data_mem  (rs2_data_mem),
    .rd_mem        (rd_idx_mem),
    .wb_mux_sel_mem(wb_mux_sel_mem),
    .reg_file_wr_mem(reg_file_wr_mem),
    .mem_read_mem  (mem_read_mem),
    .mem_write_mem (mem_write_mem),
    .one_byte_mem  (one_byte_mem),
    .two_bytes_mem (two_bytes_mem),
    .four_bytes_mem(four_bytes_mem)
  );

  // ------------------------------------------------------------
  // MEM stage
  // ------------------------------------------------------------
  data_mem #(.WIDTH(WIDTH), .DEPTH(DATA_MEM_DEPTH)) u_ram (
    .clk        (clk_i),
    .rst        (rst_i),
    .data_in    (rs2_data_mem),
    .addr       (alu_out_mem[DATA_MEM_DEPTH-1:0]),
    .wr         (mem_write_mem),
    .rd         (mem_read_mem),
    .one_byte   (one_byte_mem),
    .two_bytes  (two_bytes_mem),
    .four_bytes (four_bytes_mem),
    .data_out   (mem_data_mem)
  );

  // ------------------------------------------------------------
  // MEM/WB
  // ------------------------------------------------------------
  mem_wb_reg #(.WIDTH(WIDTH)) u_mem_wb (
    .clk            (clk_i),
    .rst            (rst_i),
    .en             (1'b1),
    .flush          (1'b0),
    .mem_data_mem   (mem_data_mem),
    .alu_out_mem    (alu_out_mem),
    .pc4_mem        (pc4_mem),
    .pcimm_mem      (pcimm_mem),
    .rd_mem         (rd_idx_mem),
    .wb_mux_sel_mem (wb_mux_sel_mem),
    .reg_file_wr_mem(reg_file_wr_mem),
    .mem_data_wb    (mem_data_wb),
    .alu_out_wb     (alu_out_wb),
    .pc4_wb         (pc4_wb),
    .pcimm_wb       (pcimm_wb),
    .rd_wb          (rd_idx_wb),
    .wb_mux_sel_wb  (wb_mux_sel_wb),
    .reg_file_wr_wb (reg_file_wr_wb)
  );

  // ------------------------------------------------------------
  // WB stage
  // ------------------------------------------------------------
  mux_4_1 #(.WIDTH(WIDTH)) u_wb_mux (
    .A   (alu_out_wb),
    .B   (mem_data_wb),
    .C   (pc4_wb),
    .D   (pcimm_wb),
    .sel (wb_mux_sel_wb),
    .out (wb_data)
  );

  // ------------------------------------------------------------
  // NEXT PC (PC selection usando decisión en EX)
  // ------------------------------------------------------------
  always_comb begin
    case (if_mux_sel_ex)
      2'd0: pc_next = pc_4_if;       // flujo normal
      2'd1: pc_next = pcimm_ex;      // BR/JAL: PC+IMM (desde EX)
      2'd2: pc_next = jalr_target_ex;// JALR
      default: pc_next = pc_4_if;
    endcase
  end

  // ------------------------------------------------------------
  // Mapeo + señales internas que usa el testbench
  // ------------------------------------------------------------
  assign ProgAddress_o = pc_out;
  assign DataAddress_o = alu_out_mem;
  assign DataOut_o     = rs2_data_mem;
  assign we_o          = mem_write_mem;

  
  logic [WIDTH-1:0] alu_out;
  logic [WIDTH-1:0] rs2_data;
  logic             mem_write;
  logic             one_byte;

  assign alu_out    = alu_out_mem;
  assign rs2_data   = rs2_data_mem;
  assign mem_write  = mem_write_mem;
  assign one_byte   = one_byte_mem;

  
  logic [WIDTH-1:0] instruction;
  assign instruction = instr_id;

endmodule
