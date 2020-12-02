#!python3

# Copyright GMicro UFSM 2020.
# This source describes Open Hardware and is licensed under the CERN-OHLS v2
# You may redistribute and modify this documentation and make products
# using it under the terms of the CERN-OHL-S v2 (https:/cern.ch/cern-ohl).
# This documentation is distributed WITHOUT ANY EXPRESS OR IMPLIED
# WARRANTY, INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY
# AND FITNESS FOR A PARTICULAR PURPOSE. Please see the CERN-OHL-S v2
# for applicable conditions.
# Source location: https://github.com/vctrop/shapelet_distance_hardware_accelerator
# As per CERN-OHL-S v2 section 4, should You produce hardware based on
# these sources, You must maintain the Source Location visible on any
# product you make using this documentation.

# 3rd party modules
import numpy as np
import matplotlib.pyplot as plt

# Shapelet lengths
lengths = [3, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 128]
# Software cycles
# The last item must be replaced with the num of cycles for l = 128
cycles_sw = [445, 1266, 1863, 2336, 2822, 3308, 3806, 4291, 4778, 5276, 5762, 6250, 6746, 7130]
# Hardware cycles for P = 4, 8, 16 and 32
cycles_hw_p2 = [631, 1197, 2137, 3077, 4017, 4957, 5897, 6837, 7777, 8717, 9657, 10597, 11537, 12289]
cycles_hw_p4 = [487, 869, 1257, 1829, 2217, 2789, 3177, 3749, 4137, 4709, 5097, 5669, 6057, 6441]
cycles_hw_p8 = [527, 725, 929, 1133, 1337, 1725, 1929, 2133, 2337, 2725, 2929, 3133, 3337, 3537]
cycles_hw_p16 = [567, 581, 785, 805, 1009, 1213, 1233, 1437, 1457, 1661, 1865, 1885, 2089, 2105]
cycles_hw_p32 = [607, 621, 641, 661, 865, 885, 905, 1109, 1129, 1149, 1353, 1373, 1393, 1409]

# linestyle dictionary
ls = {'loosely dashdotted':  (0, (3, 10, 1, 10)),
      'dashdotted':          (0, (3, 5, 1, 5)),
      'dashed':              (0, (5, 5)),
      'densely dashed':      (0, (5, 1))}

plt.figure()
plt.xlim(min(lengths),max(lengths))
plt.ylim(400, 14000)
plt.xticks(lengths, fontsize = 14)
plt.yticks(fontsize = 14)
plt.yscale('log')
plt.plot(lengths, cycles_sw,     linewidth = 2, color = 'k', linestyle = (0, (5, 5)), label = 'ARMv7 software')
plt.plot(lengths, cycles_hw_p2,  linewidth = 2, color = 'rebeccapurple',label = 'Engine w/ P = 2')
plt.plot(lengths, cycles_hw_p4,  linewidth = 2, color = 'firebrick',    label = 'Engine w/ P = 4')
plt.plot(lengths, cycles_hw_p8,  linewidth = 2, color = 'darkorange',   label = 'Engine w/ P = 8')
plt.plot(lengths, cycles_hw_p16, linewidth = 2, color = 'forestgreen',  label = 'Engine w/ P = 16')
plt.plot(lengths, cycles_hw_p32, linewidth = 2, color = 'royalblue',    label = 'Engine w/ P = 32')
plt.xlabel('Shapelet length', fontsize = 18)
plt.ylabel('Nº of clock cycles', fontsize = 18)
plt.legend(fontsize = 14)
plt.show()