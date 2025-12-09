# Proyecto-2-Procesador-Multiciclo

Procesador Multiciclo de RISC-V de 32 bits con pipeline de 5 etapas utilizando SystemVerilog, capaz de ejecutar programas almacenados en un program.mem

Procesador que ejecuta dos códigos, el primero es un contador de 0 a 10, y el segundo imprime un texto "Este es el proyecto 2"

---

## Integrantes
- Anthony Chacón Montero - 2022117452 
- Tifanny Díaz Benítez - 2022209508
- Jordi Segura Chinchilla - 2022240646
- Christian Aparicio Cambronero - 2021157244


## Tabla de contenidos

- [Descripción](#descripción)
- [Características Principales](#características-principales)
- [Estructura del Procesador](#estructura-del-procesador)
- [Etapas del Pipeline](#etapas-del-pipeline)
- [Gestión de Riesgos: forwarding y hazards](#gestión-de-riesgos)
- [Memorias y formato de programa](#memorias-y-formato-de-programa)
- [Cómo ejecutar un programa](#cómo-ejecutar-un-programa)
- [Arquitectura de archivos](#arquitectura-de-archivos)
- [Imagen de referencia del procesador](#imagen-de-referencia-del-procesador)
- [Conclusiones](#conclusiones)



---

## Descripción

Este proyecto implementa un procesador RISC-V de 32 bits con pipeline de 5 etapas, escrito en SystemVerilog, capaz de ejecutar programas almacenados en un archivo program.mem 

Este procesador es una evolución del procesador uniciclo, incorporando:

- Pipeline completo.
- Forwarding para evitar stalls innecesarios.
- Hazard detection.
- Memoria de instrucciones cargada desde archivo.
- Soporte para múltiples programas ensamblados manualmente.
- Testbench verificador automático de salida UART.

El sistema es capaz de ejecutar programas simples como contadores o rutinas de cálculo.

---

## Características Principales

### Arquitectura

- Pipeline de 5 etapas: IF, ID, EX, MEM, WB
- Cumplimiento del estándar RV32I
- Soporte para instrucciones:
    - R-type
    - I-type
    - S-type
    - B-type
    - JAL/JALR
    - LUI/AUIPC
    - LOAD/STORE (byte, halfword, word)

### Pipeline avanzado

 - Forwarding.
 - Detección de hazards
 - Control centralizado vía control_deco.sv

### Memorias

- ROM configurable usando program.mem
- RAM para:
    - byte
    - accesos de 1,2 o 4 bytes
 
## Estructura del procesador

El procesador está compuesto por 18 módulos independientes:

| Componente        | Archivo            | Función |
|------------------|--------------------|---------|
| Program Counter  | register.sv            | Guarda y actualiza el PC  |
| Suma de PC + 4   | adder.sv               | Incremento del PC         |
| Memoria ROM      | inst_mem.sv            | Contiene el programa      |
| Memoria RAM      | data_mem.sv            | Memoria de datos          |
| Banco de registros| reg_file.sv           | Registros X0-X31          |
| ALU              | alu.sv                 | Ejecución de operaciones  |
| Inmediatos       | imm_gen.sv             | Decodifica tipos I/S/B/J/U|
| Control          | control_deco.sv        | Señales de control global |
| Multiplexores    | mux_2_1.sv, mux_4_1.sv | Rutas críticas            |
| Pipeline IF/ID   | if_id_reg.sv           | Separación de etapas      |
| Pipeline ID/EX   | id_ex_reg.sv           | Entrada a EX              |
| Pipeline EX/MEM  | ex_mem_reg.sv          | Salida de EX              |
| Pipeline MEM/WB  | mem_wb_reg.sv          | Entrada a WB              |
| Forwarding       | integrado en top.sv    | Corrige dependencias      |
| Hazard Unit      | hazard_unit.sv         | Detecta stall/flush       |
| TOP (CPU)        | desing.sv              | Integra todo el sistema   |
| Testbench        | testbench.sv           | Verificación automática   |


## Etapas del Pipeline

### IF-Instruction Fetch

- Se lee PC
- Se calcula PC + 4
- Se trae la instrucción desde ROM

### ID - Instruction Decode

- Se decodifica instrucción
- Se leen rs1 y rs2 del banco de registros
- Se genera inmediato
- Se revisan hazards

### EX - Execution

- ALU
- Se calcula la dirección
- Se evalúan comparaciones de branch
- Se decide el siguiente PC

### MEM - Memory 

- Lectura o escritura a RAM
- Aplica byte-enable según tamaño de acceso

### WB - Write Back

- Se selecciona entre:
    - ALU result
    - Mem data
    - PC + 4
    - PC + imm
- Se escribe en rd

## Gestión de riesgos

### Load-use hazard

Si una instrucción carga (lw, lb, ...) y la siguiente usa ese registro:

lw     x5, 0(x1)

addi   x6, x5, 4 <--- debe esperar 1 ciclo

La hazard unit inserta 1 stall.

### Branch hazard

beq x1, x2, label

Se limpia IF/ID (flush)

### Forwarding 

Evita stalls innecesarios:

- MEM --> EX
- WB  --> EX

## Memorias y formato de programa

El archivo program.mem contiene instrucciones hex RV32I, una por línea.

Ejemplo:

0x000100B7
0x04408093
0x04500113

Admite varios programas mediante:

- Bloques comentados /*...*/
- Elegir manualmente cuál dejar activo

## Cómo ejecutar un programa

1. Editar program.mem
2. Colocar solo las instrucciones del programa deseado
3. Ejecutar:
   iverilog -g2012 desing.sv testbench.sv
4. El testbench mostrará la salida "UART"

## Arquitectura de archivos 

/src

    desing.sv
    mux_2_1.sv
    mux_4_1.sv
    adder.sv
    register.sv
    reg_file.sv
    alu.sv
    imm_gen.sv
    inst_mem.sv
    data_mem.sv
    control_deco.sv
    if_id_reg.sv
    id_ex_reg.sv
    ex_mem_reg.sv
    mem_wb_reg.sv
    hazard_unit.sv

/test

     testbench.sv

program.mem

README.md 

## Imagen de referencia del procesador 

- **Procesador multiciclo con pipeline de 5 etapas**


   ![Procesador multiciclo](https://github.com/antchacon/Proyecto-2-Procesador-Multiciclo/blob/main/Multiciclo%20con%20pipeline%20de%205%20etapas.png?raw=true)


## Conclusiones

Este proyecto demuestra:

- Comprensión de la arquitectura RISC-V RV32I
- Diseño de un procesador pipeline funcional en SystemVerilog
- Implementación de forwarding y hazard
- Capacidad de ejecutar programas
- Integración con ROM externa vía program.mem
- Un testbench capaz de validar automáticamente la ejecución



