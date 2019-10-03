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
    uint16_t length;    //Number of points contained in the shapelet
    double quality;     //Quality measure value
    double * values;    //Subsequence values
} Shapelet;

// Floating-point size displaying
void fp_sizes(void);

// Returns pointer to new shapelet of a given size in a given time-series position (DESTROY THE RETURNED SHAPELET AFTER USAGE)
Shapelet *assemble_shapelet(double *time_series, uint16_t shapelet_position, uint16_t shapelet_len);
void destroy_shapelet(Shapelet *shapelet);

// Shapelet normalization (DESTROY RETURNED SHAPELET AFTER USAGE)
Shapelet *normalize_shapelet(Shapelet *shapelet);

// Fixed-point euclidean distance
// uint64_t fixp_euclidean_distance(uint32_t *pivot_shapelet, uint32_t *target_shapelet, uint16_t size);

// Floating-point euclidean distance
double fp_euclidean_distance(Shapelet *pivot_shapelet, Shapelet *target_shapelet);

// Distance from a shapelet to an entire time-series
double shapelet_ts_distance(Shapelet *pivot_shapelet, double *time_series, uint16_t ts_len);

// [HARDWARE-friendly, reducing memory transfer] Distances from all the "shapelet_len"-sized shapelets in a time series to another time series (FREE RETURNED POINTER AFTER USAGE)
double *length_wise_distances(double *pivot_ts, double *target_ts, uint16_t ts_len, uint16_t shapelet_len);

// F-Statistic based on distance measures and associated classes
double f_statistic(double *measured_distances, uint8_t *ts_classes, uint16_t num_of_ts, uint8_t num_classes);

// SHAPELET CACHED SELECTION (from algorithm 3 in "Classification of time series by shapelet transformation", Hills et al., 2013)
// Given a set T of time series attatched to labels, extract shapelets exhaustively from min to max lengths, keeping only the k best shapelets according to some criteria 
// (DESTROY ALL k RETURNED SHAPELETS AFTER USAGE)
Shapelet **shapelet_cached_selection(double **T, uint8_t *ts_classes, uint16_t num_of_ts, uint16_t ts_len, uint16_t min, uint16_t max, uint16_t k);


// CACHED SELECTION SUPPORT FUNCTIONS
// [NOT USED NOR TESTED] Generate set of all normalized candidate shapelets of a specific length (FREE ALL "num_shapelets" RETURNED POINTERS AFTER USAGE)
// double **generate_shapelet_candidates(double *time_series, uint16_t ts_len, uint16_t shapelet_len);

// Compare shapelets quality measures for sorting with qsort()
int compare_shapelets(const void *shapelet_1, const void *shapelet_2);

// Apply quick sort in a set of shapelets, ordering by quality measure
void qsort_shapelets(Shapelet **shapelet_set, uint16_t size);

// Remove self similar shapelets (shapelets with overlapping indices)
// double *remove_self_similars(){}
   
// Merge ts_shapelets with k_shapelets and keep only best k shapelets, destroying all unused shapelets and freeing ts_shapelets
Shapelet** merge_and_destroy(Shapelet** k_shapelets, uint16_t k, Shapelet** ts_shapelets, uint64_t ts_size);

#endif