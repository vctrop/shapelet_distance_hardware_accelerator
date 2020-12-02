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
import matplotlib.colors as colors
from mpl_toolkits.mplot3d import Axes3D
from matplotlib import cm

lengths = ['32', '64', '128', '256']
parallelisms = ['4', '8', '16', '32']
paralelism_colors = ['firebrick', 'darkorange', 'forestgreen', 'cornflowerblue'] 
edge_colors = ['maroon', 'orangered', 'darkgreen', 'royalblue']
fake_ticks = np.arange(4)

# Data matrices are 4x4 (lengths 32, 64, 128 and 256 x parallelisms 4, 8, 16 and 32)
# Power data matrix (max length x parallelism) in nW
power = np.array([[84425085.458, 149181730.107, 278105981.714, 524280973.589],
                  [93667749.673, 161335552.355, 286323892.557, 543259603.221],
                  [125417773.555, 180238254.314, 311157477.030, 561917433.864],
                  [146694642.041, 213250235.579, 348056718.386, 610835431.294]])
                  
# Area data matrix (max length x parallelism) in um^2
area = np.array([[1807330, 3138989, 5815497, 11120983],
                 [2126512, 3460379, 6129238, 11489433],
                 [2742981, 4078113, 6744030, 12117784],
                 [4014366, 5338615, 8032220, 13370456]])                  

# AREA 
fig = plt.figure()
axes = fig.gca(projection = '3d')
area_mm = area / (10**6)
print(area_mm)

for x, row in zip(fake_ticks, area_mm):
    axes.bar(left=fake_ticks, height=row, zs=x, zdir='y', width = 0.5, color = paralelism_colors, alpha = 0.95,
                                                                linewidth = 1, edgecolor = edge_colors)
    
axes.set_xlabel('Paralelism')
axes.set_ylabel('Max. length')
axes.set_zlabel('Area (mm²)')
axes.set_yticks(fake_ticks)
axes.set_xticks(fake_ticks)
axes.set_xticklabels(parallelisms)
axes.set_yticklabels(lengths)
axes.view_init(elev=10., azim=255)
plt.savefig('synth_area.png', dpi=300)
#plt.show()

# POWER
fig = plt.figure()
axes = fig.gca(projection = '3d')
power_nW = power / (10**6)
print(power_nW)

for x, row in zip(fake_ticks, power_nW):
    axes.bar(left=fake_ticks, height=row, zs=x, zdir='y', width = 0.5, color = paralelism_colors, alpha = 0.95,
                                                                linewidth = 1, edgecolor = edge_colors)
    
axes.set_xlabel('Paralelism')
axes.set_ylabel('Max. length')
axes.set_zlabel('Power (mW)')
axes.set_yticks(fake_ticks)
axes.set_xticks(fake_ticks)
axes.set_xticklabels(parallelisms)
axes.set_yticklabels(lengths)
axes.view_init(elev=10., azim=255)
plt.savefig('synth_power.png', dpi=300)
#plt.show()





