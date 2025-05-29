#!/bin/sh

iverilog -Wall -g2012 src/testbench.sv -o fsm.out
vvp fsm.out
gtkwave fsm.vcd