`include "src/fsm.sv"

module fsm_test;
timeunit 1ns;
timeprecision 100ps;

// вводы модуля
reg clk;
reg rst;
reg [7:0]ascii_char;
reg char_valid;

// выводы модуля
wire sequence_valid;
wire output_strobe;

// полупериод clk
localparam CLK_HALF_PERIOD = 1000000000 / 25000000 / 2; // 25 MHz
// период входного бод-рейта
localparam INPUT_BAUD_PERIOD = 1000000000 / 9600; // 9600 baud

// инстанцируем наш модуль
fsm fsm1 (
  .clk (clk),
  .rst (rst),
  .ascii_char (ascii_char),
  .char_valid (char_valid),
  .sequence_valid (sequence_valid),
  .output_strobe (output_strobe)
);

// инициализация
initial begin
  $display($time, " -- Starting simulation");
  rst = 0;
  clk = 0;
  char_valid = 0;
end

// запускаем clk
always #CLK_HALF_PERIOD clk = ~clk;

initial begin
  $dumpfile("fsm.vcd");
  $dumpvars(0, fsm_test);

  // "\0123+X\0"
  rst = 1;
  #INPUT_BAUD_PERIOD rst = 0;
  #INPUT_BAUD_PERIOD char_valid = 1; ascii_char = 8'd0;
  #INPUT_BAUD_PERIOD ascii_char = "1";
  #INPUT_BAUD_PERIOD ascii_char = "2";
  #INPUT_BAUD_PERIOD ascii_char = "3";
  #INPUT_BAUD_PERIOD ascii_char = "+";
  #INPUT_BAUD_PERIOD ascii_char = "X";
  #INPUT_BAUD_PERIOD ascii_char = 8'd0;
  #INPUT_BAUD_PERIOD char_valid = 0;
  // должно вывести 1

  // "\0456*ABC\0"
  #INPUT_BAUD_PERIOD rst = 1;
  #INPUT_BAUD_PERIOD rst = 0;
  #INPUT_BAUD_PERIOD char_valid = 1; ascii_char = 8'd0;
  #INPUT_BAUD_PERIOD ascii_char = "4";
  #INPUT_BAUD_PERIOD ascii_char = "5";
  #INPUT_BAUD_PERIOD ascii_char = "6";
  #INPUT_BAUD_PERIOD ascii_char = "*";
  #INPUT_BAUD_PERIOD ascii_char = "A";
  #INPUT_BAUD_PERIOD ascii_char = "B";
  #INPUT_BAUD_PERIOD ascii_char = "C";
  #INPUT_BAUD_PERIOD ascii_char = 8'd0;
  #INPUT_BAUD_PERIOD char_valid = 0;
  // должно вывести 1

  // "\001A+XX\0"
  #INPUT_BAUD_PERIOD rst = 1;
  #INPUT_BAUD_PERIOD rst = 0;
  #INPUT_BAUD_PERIOD char_valid = 1; ascii_char = 8'd0;
  #INPUT_BAUD_PERIOD ascii_char = "0";
  #INPUT_BAUD_PERIOD ascii_char = "1";
  #INPUT_BAUD_PERIOD ascii_char = "A";
  #INPUT_BAUD_PERIOD ascii_char = "+";
  #INPUT_BAUD_PERIOD ascii_char = "X";
  #INPUT_BAUD_PERIOD ascii_char = "X";
  #INPUT_BAUD_PERIOD ascii_char = 8'd0;
  #INPUT_BAUD_PERIOD char_valid = 0;
  // должно вывести 0

  #INPUT_BAUD_PERIOD rst = 1;
  #INPUT_BAUD_PERIOD $finish;
end

endmodule