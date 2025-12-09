// Code your testbench here
// or browse Examples
`timescale 1ns/1ps

module tb_core;

  // ===== Señales TB =====
  logic clk = 1'b0;   // reloj arranca en 0
  logic rst = 1'b1;   // reset arranca en 1

  // ===== Parámetros del DUT =====
  localparam int WIDTH           = 32;
  localparam int INST_MEM_DEPTH  = 15;   // ROM por palabras (DEPTH-2)
  localparam int REG_FILE_DEPTH  = 5;
  localparam int DATA_MEM_DEPTH  = 20;   // RAM hasta 0x0001_0000

  // ===== MMIO "UART" para impresión en consola =====
  localparam logic [31:0] UART_TX_ADDR = 32'h0001_0044;

  // ===== Control de simulación =====
  localparam int MAX_CYCLES = 2000;
  int cycles = 0;

  // ===== DUT =====
  logic [31:0] ProgAddress_o;
  logic [31:0] DataAddress_o;
  logic [31:0] DataOut_o;
  logic        we_o;

  top #(
    .WIDTH(WIDTH),
    .INST_MEM_DEPTH(INST_MEM_DEPTH),
    .REG_FILE_DEPTH(REG_FILE_DEPTH),
    .DATA_MEM_DEPTH(DATA_MEM_DEPTH),
    .INST_SIZE(32)
  ) dut (
    .clk_i         (clk),
    .rst_i         (rst),

    .ProgAddress_o (ProgAddress_o),
    .ProgIn_i      (32'b0),   // no usado (ROM interna activa)

    .DataAddress_o (DataAddress_o),
    .DataOut_o     (DataOut_o),
    .DataIn_i      (32'b0),   // no usado (RAM interna activa)

    .we_o          (we_o),
    .pc_out        (/* abierto, opcional */)
  );

  // ===== Reloj 100 MHz =====
  always #5 clk = ~clk;

  // ===== Secuencia principal sencilla =====
  initial begin
    $display("[TB] Inicio de simulación");
    // Reset breve
    repeat (4) @(posedge clk);
    rst = 1'b0;

    // Bucle principal
    forever begin
      @(posedge clk);
      cycles++;

      // "Consola" por MMIO: imprime cuando hay SB a UART_TX_ADDR
      if (dut.mem_write && dut.one_byte && (dut.alu_out == UART_TX_ADDR)) begin
        byte ch;
        ch = dut.rs2_data[7:0];

        if (ch == 8'h0A)       $write("\n");       // LF
        else if (ch == 8'h0D)  /* ignorar CR */ ;
        else                   $write("%c", ch);   // carácter ASCII
      end

      // Corte por número de ciclos
      if (cycles >= MAX_CYCLES) begin
        $display("\n[TB] Timeout a %0d ciclos. PC=0x%08x", 
                 cycles, ProgAddress_o);
        $finish;
      end
    end
  end

endmodule
