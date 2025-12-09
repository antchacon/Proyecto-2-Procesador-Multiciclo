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




---

## Descripción

Este proyecto implementa el juego Snake en ensamblador RISC-V para el simulador Ripes.  

Características principales:

- Área de juego lógica de `15×15` celdas.
- Serpiente con cola de hasta 100 segmentos.
- Manzana que aparece en posiciones pseudo-aleatorias.
- Control con D-Pad 0 de Ripes.
- Detección de colisión de la cabeza con la cola (pantalla roja).
- Condición de victoria cuando la serpiente llena el mapa (pantalla verde).

---

## Características Principales

### Controles

El juego usa el D-Pad 0 de Ripes:

- UP → Mover hacia arriba  
- DOWN → Mover hacia abajo  
- LEFT → Mover hacia la izquierda  
- RIGHT → Mover hacia la derecha  

Reglas de movimiento:

- No puedes devolverte en línea recta.
  - Si vas hacia arriba, no puedes cambiar directo a abajo.
  - Si vas hacia abajo, no puedes cambiar directo a arriba.
  - Si vas hacia izquierda, no puedes cambiar directo a derecha.
  - Si vas hacia derecha, no puedes cambiar directo a izquierda.

Esto evita que la serpiente se “autodestruya” intentando ir justo en la dirección opuesta en el mismo ciclo.

---

### Objetivo del juego

- Controlar la serpiente para:
  - Comer la manzana roja que aparece en el mapa.
  - Hacer que la serpiente crezca con cada manzana.
- Mantenerte con vida el mayor tiempo posible sin chocar contra tu propia cola.

Cada vez que se come una manzana:

1. La cola aumenta de longitud.
2. La manzana cambia de posición, evitando colocarse encima de cualquier segmento de la cola.
3. La dificultad aumenta de forma natural hay menos espacio libre para moverte.

---

### Condiciones de derrota

Pierdes la partida cuando:

- La cabeza de la serpiente choca con cualquier segmento de su cola.

Cuando esto ocurre:

- Toda la matriz LED se pone en rojo, indicando que perdió la partida.


 En esta versión no hay colisión con las paredes del mapa y el movimiento solamente se detiene en los límites.

---

### Condición de victoria

Ganas la partida cuando:

- La serpiente llena el mapa completo o en este caso al obtener 15 leds de cola (esto para efectos de tiempo y demostrar la pantalla de victoria).

Cuando esto ocurre:

- Toda la matriz LED se pone en verde, indicando que ganó la partida.


---

## Detalles visuales

Colores de la matriz LED:

- Cabeza de la serpiente: blanco (`0xFFFFFF`)
- Cola de la serpiente: verde (`0x00FF00`)
- Manzana: rojo (`0xFF0000`)
- Borde del área de juego: amarillo (`0xFFFF00`)
- Pantalla de derrota (game over): todo rojo
- Pantalla de victoria: todo verde

Tamaño de la matriz física:

- Matriz LED de 35×25 → `875` píxeles.
- El juego solo usa la esquina superior izquierda para el mapa lógico y el borde, esto ya que al usar toda la matriz conforme pasaba el tiempo se iba poniendo lento el juego, y en la esquina  para facilidad de la programación de centrar el cuadrado.

---

## Estructura del código

Principales  funciones:

- `main`  
  Inicializa posiciones, dirección, longitud de la cola y genera la primera manzana. Contiene el bucle principal del juego.

- `read_input`  
  Lee el estado del D-Pad y actualiza la dirección (`dir`) sin permitir reversas directas.

- `move_snake`  
  Actualiza la posición de la cabeza dentro del área jugable y guarda la posición anterior.

- `update_tail_history`  
  Desplaza el historial de posiciones de la cabeza y actualiza los arrays `last_x` y `last_y` para dibujar la cola.

- `check_self_collision`  
  Recorre la cola y verifica si la cabeza coincide con algún segmento. Si hay colisión, llama a `game_over`.

- `handle_apple`  
  Comprueba si la cabeza está en la misma posición que la manzana. Si es así:
  - Actualiza la semilla pseudo-aleatoria.
  - Calcula una nueva posición para la manzana, evitando la cola.
  - Incrementa `tail_len` hasta un máximo.

- `spawn_apple`  
  Genera la manzana inicial en una posición pseudo-aleatoria.

- `clear_matrix`  
  Apaga todos los LEDs de la matriz.

- `draw_head`, `draw_tail`, `draw_apple`, `draw_border`  
  Dibuja en la matriz LED la cabeza, la cola, la manzana y el borde del mapa.

- `check_win_condition`  
  Revisa si la longitud de la cola alcanza el valor de victoria y, en ese caso, llama a `game_win`.

- `game_over`, `game_win`  
  Llenan toda la matriz de rojo o verde y se quedan en un bucle infinito al finalizar.

- `delay`  
  Pequeño retardo por software que controla la velocidad del juego.  
  Puedes ajustar la constante inicial para hacerlo más rápido o más lento.

---

## Imagenes del juego 

- **D-Pad**


   ![Dpad](https://github.com/user-attachments/assets/8e0c76c3-f28c-4ceb-bb6c-3fd952b91534)


- **Matriz**


   ![matrizleds](https://github.com/user-attachments/assets/fd32873b-4cc6-460d-ae7a-72c83eb2cd24)


- **Juego**


   ![juego](https://github.com/user-attachments/assets/1737a0ad-882e-40e4-8eb0-a8fd430eaf4a)

- **Pantalla de Derrota**


   ![losescreen](https://github.com/user-attachments/assets/a61ea425-79c7-4a4c-972f-177e3cdd6ada)

- **Pantalla de Victoria**


   ![winscreen](https://github.com/user-attachments/assets/7d0e9811-6290-4fc7-aefa-cf2eae8ee650)

---
