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

#ifndef _PROFILING_AUX_H
#define _PROFILING_AUX_H

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <math.h>
#include <string.h>
#include <fenv.h>  // use -lm during compilaton to link this library

#include "shapelet_transform.h"
#include "decision_functions.h"

// Shapelet structure similar to the time-series structure in shapelet_transform.h
typedef struct{
    //uint8_t class;                      // The class of the time-series from which the shapelet was extracted
    uint16_t length;                    // Number of points in time series
    numeric_type *values;               // The shapelet itself
} Shapelet_profiling;

// Returns a new shapelet_profiling instance
// The inputs are an oversized buffer and the actual shapelet length
Shapelet_profiling profiling_init_shapelet(numeric_type **shapelet_values_buffer, uint16_t shapelet_len, numeric_type **shapelet_values);

// Reads a CSV with one shapelet in each line
void read_shapelets(const char *filename, Shapelet_profiling **shapelet_array);

// Distance from a shapelet to an entire time-series
numeric_type profiling_shapelet_ts_distance(Shapelet_profiling *normalized_shapelet, const Timeseries *time_series);

// Transform set of time-series based on the distances to a set o shapelets (the Transform of the ST)
numeric_type **profiling_transform_dataset(Timeseries *T, uint16_t num_ts, Shapelet_profiling *normalized_shapelets, uint16_t num_shapelets);

// // Compute mean and std
void comp_mean_std(numeric_type *values, uint16_t length);

void print_float_array(float * vec, size_t size);

#endif