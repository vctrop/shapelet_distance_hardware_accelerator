This file introduces the extraction of shapelet distance test vectors from datasets.

The test vector were extracted in the following way:
- All the shapelets have lengths multiple of 4, ranging from 4 to 16;
- Pivot shapelets are from Wafer dataset time-series 0, while target shapelets are from Wafer time-series 0 to 4;
- For every pivot shapelet (op 0) there are three target shapelets (op 1);
- For exponent-based early abandon, NUM_PU of 4 is considered;
- All values are 32 bit hexadecimal, with lengths being unsigned and shapelet values and distances floating points.

The debug_vector.txt content is organized as follows:
length
pivot shapelet
current minimum distance
target shapelet
expected distance
current minimum distance
target shapelet
expected distance
current minimum distance
target shapelet
expected distance
length
pivot shapelet
current minimum distance
target shapelet
expected distance
current minimum distance
target shapelet
expected distance
current minimum distance
target shapelet
expected distance
...