//  
// september, 2019

#ifndef _SHAPELET_TRANSFORM_H
#define _SHAPELET_TRANSFORM_H

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <errno.h>

// Floating-point size displaying
void fp_sizes(void);

// Shapelet normalization (FREE RETURNED POINTER AFTER USAGE)
double *normalize_shapelet(double *shapelet, uint16_t size);

// Fixed-point euclidean distance
// uint64_t fixp_euclidean_distance(uint32_t *pivot_shapelet, uint32_t *target_shapelet, uint16_t size);

// Floating-point euclidean distance
double fp_euclidean_distance(double *pivot_shapelet, double *target_shapelet, uint16_t size);

// Returns pointer to new shapelet of a given size in a given time-series position (FREE RETURNED POINTER AFTER USAGE)
double *assemble_shapelet(double *time_series, uint16_t shapelet_position, uint16_t shapelet_len);

// Distance from a shapelet to a time series
double shapelet_ts_distance(double *pivot_shapelet, uint16_t shapelet_len, double *time_series, uint16_t ts_len);

// Distances from all the l-sized shapelets in a time series to another time series (FREE RETURNED POINTER AFTER USAGE)
double *length_wise_distances(double *pivot_ts, double *target_ts, uint16_t ts_len, uint16_t shapelet_len);

// Shapelet quality measures
// F-Statistic based on distance measures and associated classes
double f_statistic(double *measured_distances, uint8_t *ts_classes);

// SHAPELET CACHED SELECTION (from algorithm 3 in "Classification of time series by shapelet transformation", Hills et al., 2013)
// Given a set T of time series attatched to labels, extract shapelets exhaustively from min to max lengths, keeping only the k best shapelets according to some criteria 
// (FREE ALL k RETURNED POINTERS AFTER USAGE)
double **shapelet_cached_selection(double **T, uint8_t *ts_classes, uint16_t num_of_ts, uint16_t ts_len, uint16_t min, uint16_t max, uint16_t k);

// CACHED SELECTION SUPPORT FUNCTIONS
// Generate set of all normalized candidate shapelets of a specific length (FREE ALL "num_shapelets" RETURNED POINTERS AFTER USAGE)
double **generate_shapelet_candidates(double *time_series, uint16_t ts_len, uint16_t shapelet_len);

// Remove self similar shapelets (shapelets with overlapping indices)
// double *remove_self_similars(){
   



#endif