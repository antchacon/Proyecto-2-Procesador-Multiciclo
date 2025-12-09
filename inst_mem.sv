`timescale 1ns/1ps
module inst_mem #(parameter WIDTH=32, parameter DEPTH=15) (
`ifdef MULTICYCLE
  input  logic             clk,
`endif
  input  logic             rst,          // no borra la ROM; solo por compatibilidad
  input  logic [WIDTH-1:0] data_in,      // ignorado (ROM)
  input  logic [DEPTH-1:0] addr,         // byte address (usamos [DEPTH-1:2])
  input  logic             wr,           // ignorado (ROM)
  input  logic             rd,
  output logic [WIDTH-1:0] data_out
);
  // índice por palabra (32 bits = 4 bytes)
  localparam WDEPTH = (DEPTH>=2)?(DEPTH-2):1;
  localparam WORDS  = (1<<WDEPTH);

  (* rom_style="block", ram_style="block" *)
  logic [WIDTH-1:0] memory [0:WORDS-1];

  // *** AJUSTA ESTE VALOR A LA CANTIDAD REAL DE PALABRAS EN program.mem ***
  localparam int LAST_INIT_WORD = 63;  // usa 0..63 -> 64 palabras

  integer i;
  initial begin
    // Relleno por defecto (NOP = 0x00000013)
    for (i = 0; i < WORDS; i++) begin
      memory[i] = 32'h00000013;
    end

    // Cargar SOLO el rango que realmente tiene el archivo
    $readmemh("program.mem", memory, 0, LAST_INIT_WORD);
  end

  wire [WDEPTH-1:0] word_idx = addr[DEPTH-1:2];

`ifdef MULTICYCLE
  always_ff @(posedge clk) begin
    if (rd) data_out <= memory[word_idx];
  end
`else
  always_comb begin
    data_out = rd ? memory[word_idx] : '0;
  end
`endif
endmodule


