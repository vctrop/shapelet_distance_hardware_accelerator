#!/bin/bash

# Defines flopoco alias
alias flopoco="docker run --rm=true -v $PWD:/flopoco_workspace flopoco"

# Makes flopoco directory if it doesnt exist and gives ownership to current user
mkdir -p flopocoCores
#sudo chown -R $USER flopocoCores/

# --- Generates Cores ---
# Single-Path FP Adder
flopoco FPAdd               n=20 wE=8 wF=23     file=false useHardMult=no TestBench dualPath=false name=fp_adder_single
    
# Other Single-Path FP Adder    
flopoco FPAddSinglePath     n=20 wE=8 wF=23     file=false useHardMult=no TestBench name=fp_adder_single2 
    
# Dual-Path FP Adder            
flopoco FPAdd               n=20 wE=8 wF=23     file=false useHardMult=no TestBench dualPath=true  name=fp_adder_dual
    
# FP Multiplier                 
flopoco FPMult              n=20 wE=8 wF=23     file=false useHardMult=no TestBench name=fp_mult
 
# FP Squarer
flopoco FPSquare            n=20 wE=8 wF_in=23  file=false useHardMult=no TestBench wF_out=23 name=fp_power

# FP Divider                
flopoco FPDiv               n=20 wE=8 wF=23     file=false useHardMult=no TestBench file=false name=fp_div
    
# FP Square Root                
flopoco FPSqrt              n=20 wE=8 wF=23     file=false useHardMult=no TestBench name=fp_sqrt

# Move files                
mv flopoco.vhdl flopocoCores/fp_adder_single.vhd        # Single-Path FP Adder
mv flopoco.vhdl flopocoCores/fp_adder_single2.vhd       # Other Single-Path FP Adder
mv flopoco.vhdl flopocoCores/fp_adder_dual.vhd          # Dual-Path FP Adder
mv flopoco.vhdl flopocoCores/fp_mult.vhd                # FP Multiplier     
mv flopoco.vhdl flopocoCores/fp_power.vhd               # FP Squarer
mv flopoco.vhdl flopocoCores/fp_div.vhd                 # FP Divider
mv flopoco.vhdl flopocoCores/fp_sqrt.vhd                # FP Square Root

 
# --- Generates Converters

# Flopoco format to IEEE 754 format
flopoco OutputIEEE wEIn=8 wFIn=23 wEOut=8 wFOut=23 name=flopoco_to_IEEE
mv flopoco.vhdl flopocoCores/flopoco_to_IEEE.vhd
 
# IEEE 754 format to flopoco format
flopoco InputIEEE wEIn=8 wFIn=23 wEOut=8 wFOut=23 name=IEEE_to_flopoco
mv flopoco.vhdl flopocoCores/IEEE_to_flopoco.vhd

sudo chown -R $USER flopocoCores/
