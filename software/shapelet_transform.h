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

// Distances from all the l-sized shapelets in a time series to another time series
double *length_wise_distances(double *pivot_ts, double *target_ts, uint16_t ts_len, uint16_t shapelet_len);


#endif