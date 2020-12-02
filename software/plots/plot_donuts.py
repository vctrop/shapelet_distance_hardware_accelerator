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


import matplotlib.pyplot as plt
import numpy as np

entities = ["Add./Sub.", "Mul.", "Div.", "Sqrt.", "Add. Tree", "Others"]
colors   = ['#ff9a52', '#ffe46b','#c4ff6b','#a3dcff','#ff6369','#cccccc']

# DATA L = 32, P = 04
total_area = 1807330
total_power = 84425085.458

areas  = [244808, 322755, 294446, 101206, 149456, 694659]
powers = [10758065.516, 6237932.023, 7130649.369, 5141432.622, 22579864.686, 32577141.242]

area_proportions  = np.array(areas) / total_area
power_proportions = np.array(powers) / total_power

print("L = 32, P = 04")
print(entities)
print("Area proportions")
print(area_proportions)
print("Power proportions")
print(power_proportions)

plt.figure()
plt.title("Area donut L = 32, P = 04")
area_pie, _      = plt.pie(area_proportions   , radius = 1.2, colors = colors)
plt.setp(area_pie, width=0.6, edgecolor='white') # 
plt.plot()

plt.figure()
plt.title("Power donut L = 32, P = 04")
power_pie, _   = plt.pie(power_proportions, radius = 1.2, colors = colors)
plt.setp(power_pie, width=0.6, edgecolor='white') # 
plt.plot()


###
# DATA L = 256, P = 32
total_area_s = 13370456
total_power_s = 610835431.294

areas_s  = [1950742, 2587756, 2358949, 101711, 1126520, 5244778]
powers_s = [83449762.222, 43389299.176, 40566951.413, 4274854.939, 179655436.869 , 259499126.675]
    
area_proportions_s  = np.array(areas_s) / total_area_s
power_proportions_s = np.array(powers_s) / total_power_s

print("L = 256, P = 32")
print(entities)
print("Area proportions")
print(area_proportions_s)
print("Power proportions")
print(power_proportions_s)

plt.figure()
plt.title("Area donut L = 256, P = 32")
area_pie_s, _      = plt.pie(area_proportions_s   , radius = 1.2, colors = colors)
plt.setp(area_pie_s, width=0.6, edgecolor='white') # 
plt.plot()

plt.figure()
plt.title("Power donut L = 256, P = 32")
power_pie_s, _   = plt.pie(power_proportions_s, radius = 1.2, colors = colors)
plt.setp(power_pie_s, width=0.6, edgecolor='white') # 
plt.plot()

plt.show()