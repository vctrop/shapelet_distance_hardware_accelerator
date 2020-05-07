// Copyright GMicro UFSM 2020.
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

#ifndef _SHAPELET_TRANSFORM_H
#define _SHAPELET_TRANSFORM_H

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <errno.h>
#include <string.h>
#include <assert.h>
#include <fenv.h>                           // change floating point rounding modes
#include <pthread.h>                        // multi thread implementation


typedef float numeric_type;


// Time series structure
typedef struct{
    uint8_t class;                      // The time series class is represented by a number
    numeric_type *values;    
    uint16_t length;                    // Number of points in time series
} Timeseries;

// Shapelet structure
typedef struct{
    uint16_t length;                    // Number of points contained in the shapelet
    numeric_type quality;               // Quality measure value
    Timeseries *Ti;                     // Timeseries from which the shapelet was extracted
    
    uint16_t start_position;            // Index position on timeseries window
} Shapelet;

// Union to represent floats as hexadecimal safely (i.e. without type punning)
typedef union {
    float f;
    uint32_t u;
} F2u;

// Allocates memory and checks for allocation error
void *safe_alloc(size_t size);

// Returns a timeseries structure of a given class 
Timeseries init_timeseries(numeric_type * values, uint8_t class, uint16_t length);

// Returns a new shapelet of a given size in a given time-series position
Shapelet init_shapelet(Timeseries *time_series, uint16_t shapelet_position, uint16_t shapelet_len);

// Z score vector normalization
void zscore_normalization(numeric_type *values, uint16_t length);

// Euclidean distance between vectors with early abandon mechanisms
numeric_type euclidean_distance(numeric_type *pivot_values, numeric_type *target_values, uint16_t length, numeric_type current_minimum_distance, uint8_t use_exp_ea);

// Distance from a shapelet to an entire time-series
numeric_type shapelet_ts_distance(Shapelet *pivot_shapelet, const Timeseries *time_series);

// Normalization and distance from a shapelet to an entire time-series using dynamic programming algorithm proposed by (Chang, 2012)
numeric_type dynamic_shapelet_ts_distance(Shapelet *pivot_shapelet, const Timeseries *time_series);

// Generic F-Statistic based on distance measures and associated binary classes
numeric_type bin_f_statistic(numeric_type *measured_distances, Timeseries *ts_set, uint16_t num_of_ts);

// SHAPELET CACHED SELECTION (from algorithm 3 in "Classification of time series by shapelet transformation", Hills et al., 2013)
// Given a set T of time series attatched to labels, extract shapelets exhaustively from min to max lengths, keeping only the k best shapelets according to some criteria 
// (FREE RETURNED SHAPELET SET AFTER USAGE)
Shapelet *shapelet_cached_selection(Timeseries * T, uint16_t num_of_ts, uint16_t min, uint16_t max, uint16_t k);

//implements shapelet_cached_selection with multiple threads
// the number of threads is the maximum threads that may be created 
// however, if min + max < num_threads, fewer threads than expected will be used
Shapelet *multi_thread_shapelet_cached_selection(Timeseries * T, uint16_t num_of_ts, const uint16_t min, const uint16_t max, uint16_t k, const uint16_t num_threads);

// Remove self similar shapelets (shapelets with overlapping indices)
Shapelet *remove_self_similars(Shapelet *ts_shapelets, uint32_t *num_shapelets);
   
// Merge ts_shapelets with k_shapelets and keep only best k shapelets
void merge_shapelets(Shapelet* k_shapelets, uint16_t k, Shapelet* ts_shapelets, uint64_t ts_num_shapelets);

// Transform set of time-series based on the distances to a set o shapelets (the Transform of the ST)
numeric_type **transform_dataset(Timeseries *T, uint16_t num_ts, Shapelet *shapelet_set, uint16_t num_shapelets);

// Print all positions of a certain shapelet as HEX
void print_shapelet_elements(const numeric_type * shapelet_values, uint16_t shapelet_len);

// Print all shapelets in a shapelet array
void print_shapelets_ids(Shapelet * S, uint16_t num_shapelets, Timeseries *T);

// Print a shapelet set into a csv file
void shapelets_to_files(Shapelet *shapelet_set, uint16_t num_shapelets, Timeseries *T, const char * filename);

// Read datasets into ts_array, loading number of time-series and time-series length from file header
// Free all float arrays from ts_array and the ts_array itself 
uint16_t read_train_dataset(char * filename, Timeseries **ts_array);

#endif
