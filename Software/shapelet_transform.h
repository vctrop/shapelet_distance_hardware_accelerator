//  
// 
// 

#ifndef _SHAPELET_TRANSFORM_H
#define _SHAPELET_TRANSFORM_H

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <errno.h>

// Floating-point size printing
void fp_sizes(void);

// Shapelet normalization
float *normalize_shapelet(float *shapelet, uint16_t size);

// Fixed-point euclidean distance
// uint64_t fixp_euclidean_distance(uint32_t *pivot_shapelet, uint32_t *target_shapelet, uint16_t size);

// Floating-point euclidean distance
double fp_euclidean_distance(float *pivot_shapelet, float *target_shapelet, uint16_t size);

#endif