// модуль Попова
`include "lib/ascii_decoder.sv"

//! =============== 1 ===============

// тут надо нарисовать автомат

//! =============== 2 ===============

// определение модуля, входы, выходы
module fsm(
  input clk,
  input rst,
  input [7:0]ascii_char,
  input char_valid,
  output reg sequence_valid,
  output reg output_strobe
);

// состояния
localparam IDLE = 3'd0;
localparam DIGITS = 3'd1;
localparam LETTERS = 3'd2;
localparam ACCEPT = 3'd3;
localparam ERROR = 3'd4;

// регистры состояний
reg[2:0] state, next_state;

// регистры счетчиков
reg[2:0] digit_count;
reg[2:0] letter_count;

// к выводам ascii_type_detector
wire start_stop;
wire number;
wire capital_letter;
wire math_symbol;

// константы для делителей частот
localparam FULL_RX = 25000000 / 9600;
localparam MID_RX = FULL_RX / 2;
localparam FULL_TX = 25000000 / 19200;
localparam MID_TX = FULL_TX / 2;

// регистры делителя на прием
reg [11:0] clk_div_rx;
reg midf_rx, fullf_rx;
reg div_rst_rx;

// регистры делителя на передачу
reg [11:0] clk_div_tx;
reg midf_tx, fullf_tx;
reg div_rst_tx;

// очистка счетчиков и флагов
wire clr_counters;

//! =============== 3 ===============

// инстанцирование модуля
ascii_type_detector type_detector (
  .ascii_char (ascii_char),
  .small_letter (),
  .capital_letter (capital_letter),
  .number (number),
  .hex_digit (),
  .punctuation_basic (),
  .punctuation_finance (),
  .parentheses (),
  .curly_braces (),
  .math_symbol (math_symbol),
  .whitespace (),
  .vowel (),
  .start_stop (start_stop),
  .other ()
);

//! =============== 4 ===============

// переход состояний по такту
always @(posedge clk) begin
  if (rst)
    state <= IDLE;
  else
    state <= next_state;
end

// ТОЛЬКО логика состояний, без IO/счетчиков
always @(*) begin
  case (state)
    IDLE: begin
      if (midf_rx && char_valid && start_stop)
        next_state = DIGITS;
      else
        next_state = IDLE;
    end

    DIGITS: begin
      if (midf_rx && char_valid && number && digit_count <= 4)
        // инкрементируем счетчик (но не здесь)
        next_state = DIGITS;
      else if (midf_rx && char_valid && math_symbol && digit_count >= 2 && digit_count <= 4)
        next_state = LETTERS;
      else if (midf_rx && char_valid && (!number && !math_symbol || digit_count > 4))
        next_state = ERROR;
      else
        next_state = DIGITS;
    end

    LETTERS: begin
      if (midf_rx && char_valid && capital_letter && letter_count <= 3)
        // инкрементируем счетчик (но не здесь)
        next_state = LETTERS;
      else if (midf_rx && char_valid && start_stop && letter_count >= 1 && letter_count <= 3)
        next_state = ACCEPT;
      else if (midf_rx && char_valid && (!capital_letter && !start_stop || letter_count > 3))
        next_state = ERROR;
      else
        next_state = LETTERS;
    end

    ACCEPT: begin
      // выводим true (но не здесь)
      if (midf_rx)
        next_state = IDLE;
      else
        next_state = ACCEPT;
    end

    ERROR: begin
      // выводим false (но не здесь)
      if (midf_rx)
        next_state = IDLE;
      else
        next_state = ERROR;
    end
  endcase
end

//! =============== 5 ===============

// делитель частоты на вход
always @(posedge clk) begin
  if (rst || div_rst_rx) begin
    // сброс
    clk_div_rx <= 0;
    midf_rx <= 0;
    fullf_rx <= 0;
  end else begin
    // инкрементируем счетчик делителя
    clk_div_rx <= clk_div_rx + 1;

    if (clk_div_rx == MID_RX) midf_rx <= 1;
    else midf_rx <= 0;

    if (clk_div_rx == FULL_RX) begin
      fullf_rx <= 1;
      // сбрасываем счетчик, т. к. отсчитали цикл,
      // важно - иначе clk_div_rx переполнится и будет неправильный период!
      clk_div_rx <= 0;
    end else fullf_rx <= 0;
  end
end

// делитель частоты на выход - аналогично
always @(posedge clk) begin
  if (rst || div_rst_tx) begin
    clk_div_tx <= 0;
    midf_tx <= 0;
    fullf_tx <= 0;
  end else begin
    clk_div_tx <= clk_div_tx + 1;

    if (clk_div_tx == MID_TX) midf_tx <= 1;
    else midf_tx <= 0;

    if (clk_div_tx == FULL_TX) begin
      fullf_tx <= 1;
      clk_div_tx <= 0;
    end else fullf_tx <= 0;
  end
end

// счетчики
always @(posedge clk) begin
  if (rst || clr_counters) begin
    digit_count <= 0;
    letter_count <= 0;
  end else if (midf_rx && char_valid) begin
    case (state)
      DIGITS: if (number) digit_count <= digit_count + 1;
      LETTERS: if (capital_letter) letter_count <= letter_count + 1;
      default: begin
        digit_count <= digit_count;
        letter_count <= letter_count;
      end
    endcase
  end
end

// сброс счетчиков при переходе в соотв состояния
assign clr_counters = (state == IDLE) || (state == ERROR) || (state == ACCEPT);

// вывод результата
always @(posedge clk) begin
  if (rst) begin
    sequence_valid <= 0;
    output_strobe <= 0;
  end else if (state == ACCEPT && fullf_tx) begin
    sequence_valid <= 1;
    output_strobe <= 1;
  end else if (state == ERROR && fullf_tx) begin
    sequence_valid <= 0;
    output_strobe <= 1;
  end else if (fullf_tx) begin
    sequence_valid <= 0;
    output_strobe <= 0;
  end
end

endmodule
