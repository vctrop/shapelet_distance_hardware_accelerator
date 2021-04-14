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
#include <time.h>

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
    uint8_t *prediction_array;
    // TLP
    char hidden_activation;
    uint16_t num_nodes;
    float **hidden_weights;
    float *out_weights; 
    
    if(argc != 2){
        fprintf(stderr, "Please specify the activation of the hidden layer ('s'igmoid or 'r'elu)\n");
        exit(-1);
    }
    hidden_activation = argv[1][0];
    
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
    
    // Randomize weights of hidden and output nodes
    srand((unsigned) time(NULL));
    num_nodes = 50;
    
    out_weights     = safe_alloc(num_nodes * sizeof(*out_weights));
    for (uint16_t i = 0; i < num_nodes; i++){
        out_weights[i] = (float) (rand() % 10000 - 5000) / 10000;
    }
    
    hidden_weights  = safe_alloc((num_shapelets + 1) * sizeof(*hidden_weights));
    for (uint16_t i = 0; i < num_shapelets + 1; i++){
        hidden_weights[i] = safe_alloc(num_nodes * sizeof(**hidden_weights));
        for (uint16_t j = 0; j < num_nodes; j++){
            hidden_weights[i][j] = (float) (rand() % 10000 - 5000) / 10000;
        }
    }
    
    // printf("Out weights\n");
    // print_float_array(out_weights, num_nodes);
    
    // printf("Hidden weights\n");
    // for(uint16_t i = 0; i < num_shapelets + 1; i++){
        // print_float_array(hidden_weights[i], num_nodes);
        // printf("\n");
    // }
    
    prediction_array = three_layer_perceptron_decision(num_ts, num_shapelets, transformed_dataset, num_nodes, hidden_weights, out_weights, hidden_activation);
    for (uint16_t i = 0; i < num_ts; i ++){
        printf("%u, ", prediction_array[i]);
    }
    
    return 0;
}