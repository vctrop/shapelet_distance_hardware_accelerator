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

entities = ["Add./Sub.", "Mul.", "Div.", "Sqrt.", "Add. Tree", "Other"]
colors =   ['#ff9a52', '#ffe46b','#c4ff6b','#a3dcff','#ff6369','#cccccc']

total_cell_area = 1198045
total_net_area  = 609285
total_static_power  = 168700.505
total_dynamic_power = 86787519.390

cell_areas  = [157588, 221335, 202458, 66221, 96116, 454339]
net_areas   = [87280, 101420, 91991, 34985, 53340, 240269]

static_powers   = [22698.146, 33355.338, 26642.433, 10046.463, 13699.074, 62259.051]
dynamic_powers  = [9713228.957, 6314236.431, 7561059.847, 4645123.022, 22179275.650, 36374596.13]

cell_proportions = np.array(cell_areas)/total_cell_area
net_proportions  = np.array(net_areas)/total_net_area
static_proportions  = np.array(static_powers)/total_static_power
dynamic_proportions = np.array(dynamic_powers)/total_dynamic_power

print(entities)
print("Net")
print(net_proportions)
#print(np.sum(net_proportions))
print("Cell")
print(cell_proportions)
#print(np.sum(cell_proportions))
print("Static")
print(static_proportions)
#print(np.sum(static_proportions))
print("Dynamic")
print(dynamic_proportions)
#print(np.sum(dynamic_proportions))

plt.figure()
plt.title("Cell donnut")
cell_pie, _     = plt.pie(cell_proportions  , radius = 1.2, colors = colors)
plt.setp(cell_pie, width=0.6, edgecolor='white') # 
plt.plot()

plt.figure()
plt.title("Net donnut")
net_pie, _      = plt.pie(net_proportions   , radius = 1.2, colors = colors)
plt.setp(net_pie, width=0.6, edgecolor='white') # 
plt.plot()

plt.figure()
plt.title("Static donnut")
static_pie, _   = plt.pie(static_proportions, radius = 1.2, colors = colors)
plt.setp(static_pie, width=0.6, edgecolor='white') # 
plt.plot()

plt.figure()
plt.title("Dynamic donnut")
dynamic_pie, _  = plt.pie(dynamic_proportions, radius = 1.2, colors = colors)
plt.setp(dynamic_pie, width=0.6, edgecolor='white') # 
plt.plot()

plt.show()