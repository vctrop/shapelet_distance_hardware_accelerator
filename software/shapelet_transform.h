//  
// september, 2019

#ifndef _SHAPELET_TRANSFORM_H
#define _SHAPELET_TRANSFORM_H

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <errno.h>
#include <string.h>
#include <assert.h>
#include <pthread.h>                        // multi thread implementation
#include "fixedptc.h"                       // Fixed point operations by Ivan Voras and Tim Hartrick 

#ifdef USE_FLOAT
    typedef float numeric_type;
#else
    #define MAX_FIXEDPT 0x7fffff00
    typedef fixedpt numeric_type;
#endif


//time series structure
typedef struct{
    uint8_t class;                      // The time series class is represented by a number
    numeric_type *values;    
    uint16_t length;                    // Number of points in time series
} Timeseries;

//Shapelet structure
typedef struct 
{
    uint16_t length;                    // Number of points contained in the shapelet
    numeric_type quality;               // Quality measure value
    Timeseries *Ti;                     // Timeseries from which the shapelet was extracted
    
    uint16_t start_position;            // Index position on timeseries window
    
    //numeric_type *Ti;                   // Timeseries values window pointer
} Shapelet;

// Allocates memory and checks for allocation error
void *safe_alloc(size_t size);

// Returns a timeseries structure of a given class 
Timeseries init_timeseries(numeric_type * values, uint8_t class, uint16_t length);

// Returns a new shapelet of a given size in a given time-series position
Shapelet init_shapelet(Timeseries *time_series, uint16_t shapelet_position, uint16_t shapelet_len);

// Generic vector normalization based on vector absolute value
void vector_normalization(numeric_type *values, uint16_t length);

// Z score vector normalization
void vector_zscore(numeric_type *values, uint16_t length);

// Generic euclidean distance
numeric_type euclidean_distance(numeric_type *pivot_values, numeric_type *target_values, uint16_t length, numeric_type current_minimum_distance);

// Distance from a shapelet to an entire time-series
numeric_type shapelet_ts_distance(Shapelet *pivot_shapelet, const Timeseries *time_series);

// [HARDWARE-friendly, reducing memory transfer] Distances from all the "shapelet_len"-sized shapelets in a time series to another time series (FREE RETURNED POINTER AFTER USAGE)
//numeric_type *length_wise_distances(Timeseries *pivot_ts, Timeseries *target_ts, uint16_t shapelet_len);

// F-Statistic based on distance measures and associated classes
//float f_statistic(float *measured_distances, uint8_t *ts_classes, uint16_t num_of_ts, uint8_t num_classes);

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

// Print all positions of a certain shapelet as HEX
void print_shapelet_elements(const numeric_type * shapelet_values, uint16_t shapelet_len);

// Print all shapelets in a shapelet array
void print_shapelets_ids(Shapelet * S, size_t num_shapelets, Timeseries *T);

// Print a shapelet set into a csv file
void shapelet_set_to_files(Shapelet *shapelet_set, size_t num_shapelets, Timeseries *T, const char * filename);

// Read datasets into ts_array, loading number of time-series and time-series length from file header
// Free all float arrays from ts_array and the ts_array itself 
uint16_t read_train_dataset(char * filename, Timeseries **ts_array);

#endif