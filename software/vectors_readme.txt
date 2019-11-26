Both normalization_vector.txt and distance_vector.txt shapelets were extracted following the same logic. Pivot shapelets are from Wafer time-series 0, while target shapelets are from Wafer time-series 1. Both of them are shapelets that begin at the start of the Time-series, and have multiples of 5 as lengths. All values are 32 bit hexadecimal.

The distance_vector.txt is organized as follows:
length
pivot shapelet
target shapelet
distance

the normalization_vector.txt is organized as follows:
length
pivot shapelet
normalized pivot shapelet
target shapelet
normalized target shapelet