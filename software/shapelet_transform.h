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

//Shapelet structure
typedef struct 
{
    uint16_t length;            //Number of points contained in the shapelet
    uint16_t start_position;    //Index position on timeseries window
    double quality;             //Quality measure value
    double * Ti;                //Timeseries window pointer
} Shapelet;


//time series structure
typedef struct{
    uint8_t class;   //The time series class is represented by a number
    double * values;    
    uint16_t length;    //numer of points in time series
} Timeseries;

// Floating-point size displaying
void fp_sizes(void);


// Returns a timeseries structure of a given class 
Timeseries init_timeseries(double * values, uint8_t class, uint16_t length);


// Returns a new shapelet of a given size in a given time-series position
Shapelet init_shapelet(double *time_series, uint16_t shapelet_position, uint16_t shapelet_len);

// Shapelet normalization
void normalize_values(double *values, uint16_t length);

// Fixed-point euclidean distance
// uint64_t fixp_euclidean_distance(uint32_t *pivot_shapelet, uint32_t *target_shapelet, uint16_t size);

// Floating-point euclidean distance
double fp_euclidean_distance(Shapelet *pivot_shapelet, Shapelet *target_shapelet);

// Distance from a shapelet to an entire time-series
double shapelet_ts_distance(Shapelet *pivot_shapelet, const Timeseries *time_series);

// [HARDWARE-friendly, reducing memory transfer] Distances from all the "shapelet_len"-sized shapelets in a time series to another time series (FREE RETURNED POINTER AFTER USAGE)
double *length_wise_distances(double *pivot_ts, Timeseries *target_ts, uint16_t shapelet_len);

// F-Statistic based on distance measures and associated classes
double f_statistic(double *measured_distances, uint8_t *ts_classes, uint16_t num_of_ts, uint8_t num_classes);

// Apply quick sort in a set of shapelets, ordering by quality measure
void qsort_shapelets(Shapelet *shapelet_set, uint16_t size);

// SHAPELET CACHED SELECTION (from algorithm 3 in "Classification of time series by shapelet transformation", Hills et al., 2013)
// Given a set T of time series attatched to labels, extract shapelets exhaustively from min to max lengths, keeping only the k best shapelets according to some criteria 
// (FREE RETURNED SHAPELET SET AFTER USAGE)
Shapelet *shapelet_cached_selection(Timeseries * T, uint16_t num_of_ts, uint16_t min, uint16_t max, uint16_t k);

// Remove self similar shapelets (shapelets with overlapping indices)
Shapelet *remove_self_similars(Shapelet *ts_shapelets, uint32_t *num_shapelets);
   
// Merge ts_shapelets with k_shapelets and keep only best k shapelets
void merge_shapelets(Shapelet* k_shapelets, uint16_t k, Shapelet* ts_shapelets, uint64_t ts_num_shapelets);

#endif