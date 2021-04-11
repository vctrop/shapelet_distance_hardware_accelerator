// Copyright GMicro UFSM 2021.
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


#include "decision_functions.h"


#include "shapelet_transform.h"

//
float dot_product(float *vector_A, float *vector_B, uint16_t length){
    float result = 0;
    
    for (uint16_t i = 0; i < length; i++){
        result += vector_A[i] * vector_B[i];
    }
    
    return result;
}

// 
uint8_t *linear_decision_function(float **transformed_dataset, uint16_t num_ts, float *coefficient_vector, uint16_t num_shapelets){
    uint8_t *classification_result;
    
    classification_result = safe_alloc( num_ts * sizeof(*classification_result) );
    
    for (uint16_t i = 0; i < num_ts; i++){
        classification_result[i] = ((uint8_t) dot_product(coefficient_vector, transformed_dataset[i], num_shapelets)) > 0;
    }
    
    return classification_result;
}