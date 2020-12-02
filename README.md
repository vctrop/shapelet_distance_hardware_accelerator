# SHAPELET DISTANCE HARDWARE ACCELERATOR


Shapelet-based methods have emerged as accurate and interpretable tools for time-series classification in machine learning applications. Although these methods find wide applicability, nowadays their use is restricted due to the heavy computational burden associated with numerous computations of z-score normalization and Euclidean distance. The current article addresses this issue with the proposal of a parameterizable parallel hardware accelerator to perform the aforementioned computations. Results show that our dedicated shapelet distance engine can significantly reduce the run time when compared with a software implementation.
<br /><br />

<p align="center">
Highly-abstracted hardware operation
<br />
</p>

<p align="center">
<img src="images/readme/shapelet_samples.png" width=500>
<br /><br />
</p>

<p align="center">
Entity Interface
<br />
</p>

<p align="center">
<img src="images/readme/entity_interface.png" width=500>
<br /><br />
</p>

<p align="center">
Control Finite-State Machine (FSM) diagram
<br />
</p>
 
<p align="center">
<img src="images/readme/shapelet_distance_fsm_diagram.png" width=500>
<br /><br />
</p>

<p align="center">
Block diagram
<br />
</p>
 
<p align="center">
<img src="images/readme/block_diagram.png" width=600>
<br /><br />
</p>

<p align="center">
Hardware vs software timing
<br />
</p>
 
<p align="center">
<img src="images/readme/timing_plot_logscale.png" width=500>
<br /><br />
</p>

<p align="center">
Total power and area proportions for different parameterizations
<br />
 
<img src="images/readme/area_and_power.png" width=500>
<br /><br />
</p>


<p align="center">
Power and area proportions among the accelerator's components for one configuration of parallelism and maximum length
<br />
 
<img src="images/readme/synthesis_donuts.png" width=500>
<br /><br />
</p>


The described shapelet distance hardware accelerator is licensed under the CERN Open Hardware License S v2, as described below.

Copyright GMicro UFSM 2020.
This source describes Open Hardware and is licensed under the CERN-OHLS v2
You may redistribute and modify this documentation and make products
using it under the terms of the CERN-OHL-S v2 (https:/cern.ch/cern-ohl).
This documentation is distributed WITHOUT ANY EXPRESS OR IMPLIED
WARRANTY, INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY
AND FITNESS FOR A PARTICULAR PURPOSE. Please see the CERN-OHL-S v2
for applicable conditions.
Source location: https://github.com/vctrop/shapelet_distance_hardware_accelerator
As per CERN-OHL-S v2 section 4, should You produce hardware based on
these sources, You must maintain the Source Location visible on any
product you make using this documentation.





