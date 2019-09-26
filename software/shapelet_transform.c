//

#include "shapelet_transform.h"

// Floating-point size displaying
void fp_sizes(void){
    printf("Float has %d bytes in this system\n", sizeof(float));
    printf("Double has %d bytes in this system\n", sizeof(double));
}

// Shapelet normalization (FREE RETURNED POINTER AFTER USAGE)
float *normalize_shapelet(float *shapelet, uint16_t size){
    double squares_sum, absolute_value;
    float *normalized_shapelet;
    uint16_t i;
    
    normalized_shapelet = (float*) malloc(size * sizeof(float));
    if (normalized_shapelet == NULL){
        perror("Error on normalized shapelet allocation:");
        exit(-1);
    }
    else{
        // Compute shapelet absolute value
        squares_sum = 0.0;
        for (i=0; i<size; i++)
            squares_sum += pow(shapelet[i], 2);
        absolute_value = sqrt(squares_sum);
        //printf("Absolute value is %lf\n", absolute_value);
        
        // Compute normalized shapelet values
        for (i=0; i<size; i++)
            normalized_shapelet[i] = shapelet[i]/absolute_value;
    }
    
    return normalized_shapelet;
}

// Fixed-point euclidean distance
// uint64_t fixp_euclidean_distance(uint32_t *pivot_shapelet, uint32_t *target_shapelet, uint16_t size){}

// Floating-point euclidean distance
double fp_euclidean_distance(float *pivot_shapelet, float *target_shapelet, uint16_t size){
    uint16_t i;
    double partial_distance, total_distance;
    
    total_distance = 0.0;
    for (i = 0; i < size; i++){
        partial_distance = pow(pivot_shapelet[i] - target_shapelet[i],2);
        total_distance += partial_distance;
    }
    
    return total_distance;
}

// Distance from a shapelet to an entire time-series
double shapelet_ts_distance(float *pivot_shapelet, uint16_t shapelet_len, float *time_series, uint16_t ts_len){
    double shapelet_distance, minimum_distance = INFINITY;
    float *ts_shapelet;
    float *norm_pivot_shapelet, *norm_ts_shapelet;
    uint16_t i, j, num_shapelets;
    
    num_shapelets = ts_len - shapelet_len + 1;                          // number of shapelets of length "shapelet_len" in time_series
    ts_shapelet = (float*) malloc(shapelet_len * sizeof(float));        // array to temporarily store shapelets of the time-series
    
    // Loops over shapelets in the time-series
    for (i=0; i<num_shapelets; i++){
        // Assemble shapelet i
        printf("TS shapelet %d\n", i); 
        for(j=i; j<(i + shapelet_len); j++){
            printf("%.4f ", time_series[j]);
            ts_shapelet[j-i] = time_series[j];
        }
        printf("\n");
        
        // Normalize pivot and time-series shapelets
        norm_pivot_shapelet = normalize_shapelet(pivot_shapelet, shapelet_len);
        norm_ts_shapelet = normalize_shapelet(ts_shapelet, shapelet_len);
        free(ts_shapelet);
        
        // Compute shapelet-shapelet distance
        shapelet_distance = fp_euclidean_distance(norm_pivot_shapelet, norm_ts_shapelet, shapelet_len);
        free(norm_pivot_shapelet);
        free(norm_ts_shapelet);
        
        // Keep the minimum distance between the pivot shapelet and all the time-series shapelets
        if (shapelet_distance < minimum_distance)
            minimum_distance = shapelet_distance;
    }
    
    return minimum_distance;
}
