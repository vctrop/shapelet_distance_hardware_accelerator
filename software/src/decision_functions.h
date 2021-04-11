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
float dot_product(float *vector_A, float *vector_B, uint16_t length);

//
uint8_t *linear_decision_function(float **transformed_dataset, uint16_t num_ts, float *coefficient_vector, uint16_t num_shapelets);

//
//float *sigmoid_activation();

//
//float *relu_activation();

//
//float matrix_vector_multiplication();


#endif