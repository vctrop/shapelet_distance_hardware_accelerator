//

#include "shapelet_transform.h"

// Floating-point size testing
void fp_sizes(void){
    printf("Float has %d bytes in this system\n", sizeof(float));
    printf("Double has %d bytes in this system\n", sizeof(double));
}

// Shapelet normalization
float *normalize_shapelet(float *shapelet, uint16_t size){
    double squares_sum, absolute_value;
    float *normalized_shapelet;
    int i;
    
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
        printf("Absolute value is %lf\n", absolute_value);
        
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
    int i;
    double partial_distance, total_distance;
    
    total_distance = 0.0;
    for (i = 0; i < size; i++){
        partial_distance = pow(pivot_shapelet[i] - target_shapelet[i],2);
        total_distance += partial_distance;
    }
    
    return total_distance;
}

