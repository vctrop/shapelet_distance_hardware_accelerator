// Copyright GMicro UFSM 2021
// This source describes Open Hardware and is licensed under the CERN-OHLS v2
// You may redistribute and modify this documentation and make products
// using it under the terms of the CERN-OHL-S v2 (https:/cern.ch/cern-ohl).
// This documentation is distributed WITHOUT ANY EXPRESS OR IMPLIED
// WARRANTY, INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY
// AND FITNESS FOR A PARTICULAR PURPOSE. Please see the CERN-OHL-S v2
// for applicable conditions.
// Source location: https://github.com/vctrop/shapelet_distance_hardware_accelerator
// As per CERN-OHL-S v2 section 4, should You produce hardware based on
// these sources, You must maintain the Source Location visible on any
// product you make using this documentation.

#include "profiling_aux.h"


int main(int argc, char *argv[]){
    Shapelet_profiling *shapelet_array;
    Shapelet_profiling *normalized_shapelet_array;
    Timeseries *ts_dataset;
    const char shapelets_filename[] = "GunPoint_extracted_3_150_data.csv";
    char dataset_filename[] = "../data/GunPoint/GunPoint_TEST.csv";
    const uint16_t num_shapelets = 50;
    uint16_t num_ts;
    // Inference
    numeric_type **transformed_dataset;
    float coefficient_vector[] = {-0.3231, -0.0882, 0.3912, -0.4085, -0.1971, 0.4187, 0.2481, -0.3782, 0.0274, 0.2563, 0.0705, -0.2876, 0.0884, 0.3504, 0.471, 0.1362, -0.2665, -0.0046, -0.3454, -0.4375, 0.2649, 0.099, -0.478, 0.3778, 0.0949, 0.4118, -0.2697, 0.4153, -0.2043, 0.1931, 0.1049, 0.0274, -0.2616, -0.3808, -0.0066, 0.2419, 0.0981, 0.3249, -0.457, 0.2094, -0.2065, 0.1235, 0.2877, -0.0819, -0.2903, -0.4882, 0.2769, 0.4899, -0.1204, -0.2903};
    uint8_t *prediction_array;
    
    // Load dataset
    num_ts = read_dataset(dataset_filename, &ts_dataset);
    
    // Load shapelet set
    shapelet_array = safe_alloc(num_shapelets * sizeof(*shapelet_array));
    read_shapelets(shapelets_filename, &shapelet_array);
    
    // Normalize shapelet set
    normalized_shapelet_array = safe_alloc(num_shapelets * sizeof(*normalized_shapelet_array));
    memcpy(normalized_shapelet_array, shapelet_array, num_shapelets * sizeof(*shapelet_array));
    
    // printf("Normalized shapelets\n");
    for (uint16_t i = 0; i < num_shapelets; i++){
        zscore_normalization(normalized_shapelet_array[i].values, normalized_shapelet_array[i].length);
        
        // printf("[%u] Length: %u, first: %g, last: %g\n", i, normalized_shapelet_array[i].length,
                // normalized_shapelet_array[i].values[0], normalized_shapelet_array[i].values[normalized_shapelet_array[i].length - 1]);
        // comp_mean_std(normalized_shapelet_array[i].values, normalized_shapelet_array[i].length);
    }
    
    // Transform the dataset with the already normalized shapelets
    transformed_dataset = profiling_transform_dataset(ts_dataset, num_ts, normalized_shapelet_array, num_shapelets);
    
    
    prediction_array = linear_decision(transformed_dataset, num_ts, coefficient_vector, num_shapelets);
    for (uint16_t i = 0; i < num_ts; i ++){
        printf("%u, ", prediction_array[i]);
    }
    
    return 0;
}