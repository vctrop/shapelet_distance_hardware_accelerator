// Copyright GMicro UFSM 2021
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

// Code snippet used in profiling
// Load a set of shapelets from a CSV file,
//      normalize them, transform a dataset and
//      apply inference with a linear classifier.

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <math.h>
#include <string.h>
#include <fenv.h>  // use -lm during compilaton to link this library

#include "shapelet_transform.h"
#include "decision_functions.h"
// Shapelet structure similar to the time-series structure in shapelet_transform.h
typedef struct{
    //uint8_t class;                      // The class of the time-series from which the shapelet was extracted
    uint16_t length;                    // Number of points in time series
    numeric_type *values;               // The shapelet itself
} Shapelet_profiling;

// Returns a new shapelet_profiling
// The inputs are an oversized buffer and the actual shapelet length
Shapelet_profiling inference_init_shapelet(numeric_type **shapelet_values_buffer, uint16_t shapelet_len, numeric_type **shapelet_values){
    Shapelet_profiling shapelet;
    
    *shapelet_values = safe_alloc(shapelet_len * sizeof(**shapelet_values) );
    memcpy(*shapelet_values, *shapelet_values_buffer, shapelet_len * sizeof(**shapelet_values) );
    
    shapelet.length = shapelet_len;
    shapelet.values = *shapelet_values;
    
    return shapelet;
    
}

// Reads a CSV with one shapelet in each line
void read_shapelets(const char *filename, Shapelet_profiling **shapelet_array){
    FILE *file_descriptor;
    char *field;
    //char *field_temp;
    const uint16_t SHAPELET_BSIZE = 500;
    const uint16_t num_shapelets = 50;
    char *shapelet_buffer;
    const uint16_t max_shapelet_len = 150;
    uint16_t shapelet_len = 0;
    float *shapelet_values_buffer;
    float *shapelet_values;
    uint8_t end_of_shapelet;
    
    *shapelet_array = safe_alloc(num_shapelets * sizeof(**shapelet_array));
    // Allocate memory for shapelet values considering the maximum length
    shapelet_values_buffer = safe_alloc(max_shapelet_len * sizeof(*shapelet_values_buffer));
        
    // Load CSV
    file_descriptor =  fopen(filename, "r");
    if (file_descriptor == NULL){
        perror("Error opening CSV: ");
        exit(errno);
    }
    
    // Allocate memory for the buffer that holds each line of the CSV
    shapelet_buffer = safe_alloc(SHAPELET_BSIZE * sizeof(*shapelet_buffer));
    
    // Read shapelets from the input CSV
    for (uint16_t i = 0; i < num_shapelets; i++){
        if(!fgets(shapelet_buffer, SHAPELET_BSIZE, file_descriptor)){
            perror("Error reading shapelet buffer: ");
            exit(errno);
        }
        // If SHAPELET_BSIZE is enought to read a line of the dataset, the '\n' will be found in shaplet_buffer, else exit
        if (!strchr(shapelet_buffer, '\n')) {
            printf("\nSHAPELET_BSIZE is not larger than number of characters in a line\n");
            exit(-1);
        }
        
        // Load shapelet values until the end of line is reached
        // Shapelet lengths are not previously known
        end_of_shapelet = 0;
         
        field = strtok(shapelet_buffer, ",");
        if (!strcmp(field, "\n"))
            end_of_shapelet = 1;
        
        for (uint16_t j = 0; j < max_shapelet_len; j++){
            // Zero padding until max len of the buffer
            if (end_of_shapelet){
                shapelet_values_buffer[j] = 0;
            }
            else{
                shapelet_values_buffer[j] = atof(field);
                
                shapelet_len++;
                field = strtok(NULL, ",");
                
                // '\n' is together with the last value, therefore we add it to the buffer and begin zero-padding
                if (strchr(field, '\n')){
                    j = j + 1;
                    shapelet_values_buffer[j] = atof(field);
                    shapelet_len = j + 1;
                    
                    end_of_shapelet = 1;
                }
            }
        }
    
        (*shapelet_array)[i] = inference_init_shapelet(&shapelet_values_buffer, shapelet_len, &shapelet_values);
    }
    
    free(shapelet_values_buffer);
    free(shapelet_buffer);
}

// Distance from a shapelet to an entire time-series
numeric_type inference_shapelet_ts_distance(Shapelet_profiling *normalized_shapelet, const Timeseries *time_series){
    numeric_type shapelet_distance, minimum_distance;
    numeric_type *subsequence_values;                                              
    const uint32_t num_shapelets = time_series->length - normalized_shapelet->length + 1;         
    
    minimum_distance = INFINITY;
    
    // Allocate memory for target values 
    // Pivot shapelet and ts shapelets must always have equal length
    subsequence_values = safe_alloc(normalized_shapelet->length * sizeof(*subsequence_values));

    // Loops over shapelets in the time-series
    for(uint32_t i=0; i<num_shapelets; i++){
        // initialize normalized values of time series shapelet starting at i
        memcpy(subsequence_values, &time_series->values[i], normalized_shapelet->length * sizeof(*subsequence_values));
        
        // Normalize target shapelet values
        zscore_normalization(subsequence_values, normalized_shapelet->length);
        
        // Compute shapelet-shapelet distance
        shapelet_distance = euclidean_distance(normalized_shapelet->values, subsequence_values, normalized_shapelet->length, minimum_distance);
        
        // Keep the minimum distance between the pivot shapelet and all the time-series shapelets
        if (shapelet_distance < minimum_distance){
            minimum_distance = shapelet_distance;
        }    
    }

    free(subsequence_values);

    return minimum_distance;
}


// Transform set of time-series based on the distances to a set o shapelets (the Transform of the ST)
numeric_type **inference_transform_dataset(Timeseries *T, uint16_t num_ts, Shapelet_profiling *normalized_shapelets, uint16_t num_shapelets){
    numeric_type **transformed_data;
    
    transformed_data = safe_alloc(num_ts * sizeof(*transformed_data));
    for (uint16_t i = 0; i < num_ts; i++){
        transformed_data[i] = safe_alloc(num_shapelets * sizeof(**transformed_data));
    }
    
    for (uint16_t i = 0; i < num_ts; i++){
        for (uint16_t j = 0; j < num_shapelets; j++){
            transformed_data[i][j] = inference_shapelet_ts_distance(&normalized_shapelets[j], &T[i]);
        }
    }
    
    return transformed_data;
}

// // Compute mean and std
void comp_mean_std(numeric_type *values, uint16_t length){
    numeric_type mean, std;
    
    // Computation of standard deviation by sample formula
    numeric_type differrence_sum;
    
    // calculate arithmetic mean 
    mean = 0;
    for(uint16_t i=0; i < length; i++){
        mean += values[i];
    }
    mean /= length;
    
    // calculate sum (xi - mean)^2
    differrence_sum = 0;
    for(uint16_t i=0; i < length; i++){
        differrence_sum += pow(values[i] - mean, 2);
    }
    // divide sum by N - 1 
    differrence_sum /= (length - 1); // this is sample std deviation. Remove the -1 to make it population std_dev
    // take the sqrt
    std = sqrt(differrence_sum);
    
    printf("Mean: %g, std: %g\n", mean, std);

}

void print_float_array(float * vec, size_t size){
    for(int i=0; i < size; i++)
        printf("%g ", vec[i]);
    printf("\n");
}



int main(int argc, char *argv[]){
    Shapelet_profiling *shapelet_array;
    Shapelet_profiling *normalized_shapelet_array;
    Timeseries *ts_dataset;
    const char shapelets_filename[] = "GunPoint_extracted_3_150_data.csv";
    char dataset_filename[] = "../data/GunPoint/GunPoint_TEST.csv";
    const uint16_t num_shapelets = 50;
    uint16_t num_ts;
    // Inference
    numeric_type **transformed_dataset;
    float coefficient_vector[] = {-0.3231, -0.0882, 0.3912, -0.4085, -0.1971, 0.4187, 0.2481, -0.3782, 0.0274, 0.2563, 0.0705, -0.2876, 0.0884, 0.3504, 0.471, 0.1362, -0.2665, -0.0046, -0.3454, -0.4375, 0.2649, 0.099, -0.478, 0.3778, 0.0949, 0.4118, -0.2697, 0.4153, -0.2043, 0.1931, 0.1049, 0.0274, -0.2616, -0.3808, -0.0066, 0.2419, 0.0981, 0.3249, -0.457, 0.2094, -0.2065, 0.1235, 0.2877, -0.0819, -0.2903, -0.4882, 0.2769, 0.4899, -0.1204, -0.2903};
    uint8_t *inference_results;
    
    // Load dataset
    num_ts = read_dataset(dataset_filename, &ts_dataset);
    
    // Load shapelet set
    read_shapelets(shapelets_filename, &shapelet_array);
    
    // printf("Raw shapelets\n");
    // for (uint16_t i = 0; i < num_shapelets; i++){
        // printf("[%u] Length: %u, first: %g, last: %g\n", i, shapelet_array[i].length,
                // shapelet_array[i].values[0], shapelet_array[i].values[shapelet_array[i].length - 1]);
        // comp_mean_std(shapelet_array[i].values, shapelet_array[i].length);
    // }

    // Normalize shapelet set
    normalized_shapelet_array = safe_alloc(num_shapelets * sizeof(*normalized_shapelet_array));
    memcpy(normalized_shapelet_array, shapelet_array, num_shapelets * sizeof(*shapelet_array));
    
    // printf("Normalized shapelets\n");
    for (uint16_t i = 0; i < num_shapelets; i++){
        zscore_normalization(normalized_shapelet_array[i].values, normalized_shapelet_array[i].length);
        
        // printf("[%u] Length: %u, first: %g, last: %g\n", i, normalized_shapelet_array[i].length,
                // normalized_shapelet_array[i].values[0], normalized_shapelet_array[i].values[normalized_shapelet_array[i].length - 1]);
        // comp_mean_std(normalized_shapelet_array[i].values, normalized_shapelet_array[i].length);
    }
    
    // Transform the dataset with the already normalized shapelets
    transformed_dataset = inference_transform_dataset(ts_dataset, num_ts, normalized_shapelet_array, num_shapelets);
    
    // for (uint16_t i = 0; i < num_ts; i++){
        // print_float_array(transformed_dataset[i], num_shapelets);
    // }
    
    
    // Inference with a linear classifier: dot product of each line of the transformed dataset with an arbitrary coefficient vector
    // // Randomize coefficient vector
    // coefficient_vector = safe_alloc(num_shapelets * sizeof(*coefficient_vector));
    // srand((unsigned) time(NULL));
    // for (uint16_t i = 0; i < num_shapelets; i++){
        // coefficient_vector[i] = (float) (rand() % 10000 - 5000) / 10000;
        // printf("%g, ", coefficient_vector[i]);
    // }
    
    inference_results = linear_decision(transformed_dataset, num_ts, coefficient_vector, num_shapelets);
    for (uint16_t i = 0; i < num_ts; i ++)
        printf("%u, ", inference_results[i]);
    
    return 0;
}