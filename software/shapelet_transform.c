//
// september, 2019

#include "shapelet_transform.h"

// Floating-point size displaying
void fp_sizes(void){
    printf("Float has %d bytes in this system\n", sizeof(float));
    printf("Double has %d bytes in this system\n", sizeof(double));
}


// Shapelet normalization (FREE RETURNED POINTER AFTER USAGE)
double *normalize_shapelet(double *shapelet, uint16_t size){
    double squares_sum, absolute_value;
    double *normalized_shapelet;
    uint16_t i;
    
    normalized_shapelet = (double*) malloc(size * sizeof(double));
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
double fp_euclidean_distance(double *pivot_shapelet, double *target_shapelet, uint16_t size){
    uint16_t i;
    double partial_distance, total_distance;
    
    total_distance = 0.0;
    for (i = 0; i < size; i++){
        partial_distance = pow(pivot_shapelet[i] - target_shapelet[i],2);
        total_distance += partial_distance;
    }
    
    return total_distance;
}


// Returns pointer to new shapelet of a given size in a given time-series position (FREE RETURNED POINTER AFTER USAGE)
double *assemble_shapelet(double *time_series, uint16_t shapelet_position, uint16_t shapelet_len){
    uint16_t i;
    double *shapelet;
   
    shapelet = (double*) malloc(shapelet_len * sizeof(double));
    
    // Assemble shapelet by accessing time series positions
    for(i = shapelet_position; i < (shapelet_position + shapelet_len); i++){
        //printf("%.4f ", time_series[i]);
        shapelet[i - shapelet_position] = time_series[i];
    }
    //printf("\n");
    
    return shapelet;
}


// Distance from a shapelet to an entire time-series
double shapelet_ts_distance(double *pivot_shapelet, uint16_t shapelet_len, double *time_series, uint16_t ts_len){
    double shapelet_distance, minimum_distance = INFINITY;
    double *ts_shapelet;
    double *norm_pivot_shapelet, *norm_ts_shapelet;
    uint16_t i, j, num_shapelets;
    
    num_shapelets = ts_len - shapelet_len + 1;                          // number of shapelets of length "shapelet_len" in time_series
    // Loops over shapelets in the time-series
    for (i=0; i<num_shapelets; i++){
        // Assemble shapelet i
        ts_shapelet = assemble_shapelet(time_series, i, shapelet_len);
        
        // Normalize pivot and time-series shapelets
        norm_pivot_shapelet = normalize_shapelet(pivot_shapelet, shapelet_len);
        norm_ts_shapelet = normalize_shapelet(ts_shapelet, shapelet_len);
        free(ts_shapelet);
        
        // Compute shapelet-shapelet distance
        shapelet_distance = fp_euclidean_distance(norm_pivot_shapelet, norm_ts_shapelet, shapelet_len);
        printf("Distance from pivot shapelet to %dth time series shapelet is %.5f\n", i, shapelet_distance); 
        free(norm_pivot_shapelet);
        free(norm_ts_shapelet);
        
        // Keep the minimum distance between the pivot shapelet and all the time-series shapelets
        if (shapelet_distance < minimum_distance)
            minimum_distance = shapelet_distance;
    }
    
    return minimum_distance;
}


// Distances from all the "shapelet_len"-sized shapelets in a time series to another time series (FREE RETURNED POINTER AFTER USAGE)
double *length_wise_distances(double *pivot_ts, double *target_ts, uint16_t ts_len, uint16_t shapelet_len){
    uint16_t i, j, num_shapelets;
    double *pivot_shapelet, *shapelets_target_distances, distance;
    
    num_shapelets = (ts_len - shapelet_len + 1);
    shapelets_target_distances = (double*) malloc(num_shapelets * sizeof(double));           // Array of all "shapelet_len"-sized distances to a given time series
    
    for(i = 0; i < num_shapelets; i++){
        pivot_shapelet = assemble_shapelet(pivot_ts, i, shapelet_len);
        distance = shapelet_ts_distance(pivot_shapelet, shapelet_len, target_ts, ts_len);
        shapelets_target_distances[i] = distance;
        printf("Distance from shapelet %d of pivot TS to target TS: %.5lf \n", i, distance);
        free(pivot_shapelet);
    }
    
    return shapelets_target_distances;
}