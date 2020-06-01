#!/bin/bash

# Defines flopoco alias
alias flopoco="docker run --rm=true -v $PWD:/flopoco_workspace flopoco"

# Makes flopoco directory if it doesnt exist and gives ownership to current user
mkdir -p flopocoCores
#sudo chown -R $USER flopocoCores/

# --- Generates Cores ---

# Single-Path FP Adder
flopoco FPAdd wE=8 wF=23 dualPath=false TestBench n=20 file=false name=fp_adder_single
mv flopoco.vhdl flopocoCores/fp_adder_single.vhd

# Other Single-Path FP Adder
flopoco FPAddSinglePath wE=8 wF=23 TestBench n=20 file=false name=fp_adder_single2
mv flopoco.vhdl flopocoCores/fp_adder_single2.vhd
 
# Dual-Path FP Adder
flopoco FPAdd wE=8 wF=23 dualPath=true TestBench n=20 file=false name=fp_adder_dual
mv flopoco.vhdl flopocoCores/fp_adder_dual.vhd
 
# FP Multiplier 
flopoco FPMult wE=8 wF=23 TestBench n=20 file=false name=fp_mult
mv flopoco.vhdl flopocoCores/fp_mult.vhd
 
# FP Squarer
flopoco FPSquare wE=8 wF_in=23 wF_out=23 TestBench n=20 file=false name=fp_power
mv flopoco.vhdl flopocoCores/fp_power.vhd
 
# FP Divider
flopoco FPDiv wE=8 wF=23 TestBench n=20 file=false name=fp_div
mv flopoco.vhdl flopocoCores/fp_div.vhd
 
# FP Square Root
flopoco FPSqrt wE=8 wF=23 TestBench n=20 file=false name=fp_sqrt
mv flopoco.vhdl flopocoCores/fp_sqrt.vhd
 
# --- Generates Converters

# Flopoco format to IEEE 754 format
flopoco OutputIEEE wEIn=8 wFIn=23 wEOut=8 wFOut=23 name=flopoco_to_IEEE
mv flopoco.vhdl flopocoCores/flopoco_to_IEEE.vhd
 
# IEEE 754 format to flopoco format
flopoco InputIEEE wEIn=8 wFIn=23 wEOut=8 wFOut=23 name=IEEE_to_flopoco
mv flopoco.vhdl flopocoCores/IEEE_to_flopoco.vhd

sudo chown -R $USER flopocoCores/
