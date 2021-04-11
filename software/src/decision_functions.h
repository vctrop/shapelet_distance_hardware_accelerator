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

#ifndef _DECISION_FUNCTIONS_H
#define _DECISION_FUNCTIONS_H

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <errno.h>
#include <string.h>
#include <assert.h>
#include <fenv.h>

//
void matrix_vector_multiplication(uint16_t n_row, uint16_t n_col, float **in_matrix, float *in_vector, float *out_vector);

// // 
// void matrix_multiplication(uint16_t n_row_m1, uint16_t n_col_m1_row_m2, float **in_matrix_A, float **in_matrix_B, float **out_matrix);

//
uint8_t *linear_decision(float **transformed_dataset, uint16_t num_ts, float *coefficient_vector, uint16_t num_shapelets);

// //
// inline float sigmoid_activation(float x);

// //
// inline float relu_activation(float x);

#endif