#!/bin/bash

# Defines flopoco alias
alias flopoco="docker run --rm=true -v $PWD:/flopoco_workspace flopoco"

# Makes flopoco directory if it doesnt exist and gives ownership to current user
mkdir -p flopocoCores
#sudo chown -R $USER flopocoCores/

# --- Generates Cores ---

# Single-Path FP Adder
flopoco FPAdd wE=8 wF=23 dualPath=false TestBench n=20 file=false
mv flopoco.vhdl flopocoCores/FPSinglePathAdder.vhd

# Other Single-Path FP Adder
flopoco FPAddSinglePath wE=8 wF=23 TestBench n=20 file=false
mv flopoco.vhdl flopocoCores/FPSinglePathAdderAlt.vhd

# Dual-Path FP Adder
flopoco FPAdd wE=8 wF=23 dualPath=true TestBench n=20 file=false
mv flopoco.vhdl flopocoCores/FPDualPathAdder.vhd

# FP Multiplier
flopoco FPMult wE=8 wF=23 TestBench n=20 file=false
mv flopoco.vhdl flopocoCores/FPMult.vhd

# FP Squarer
flopoco FPSquare wE=8 wF_in=23 wF_out=23 TestBench n=20 file=false
mv flopoco.vhdl flopocoCores/FPSquare.vhd

# FP Divider
flopoco FPDiv wE=8 wF=23 TestBench n=20 file=false
mv flopoco.vhdl flopocoCores/FPDiv.vhd

# FP Square Root
flopoco FPSqrt wE=8 wF=23 TestBench n=20 file=false
mv flopoco.vhdl flopocoCores/FPSqrt.vhd

# --- Generates Converters

# Flopoco format to IEEE 754 format
flopoco OutputIEEE wEIn=8 wFIn=23 wEOut=8 wFOut=23
mv flopoco.vhdl flopocoCores/flopocoToIEEE.vhd

# IEEE 754 format to flopoco format
flopoco InputIEEE wEIn=8 wFIn=23 wEOut=8 wFOut=23
mv flopoco.vhdl flopocoCores/IEEEToFlopoco.vhd


# Gives ownership of created files to current user
sudo chown -R $USER flopocoCores/

