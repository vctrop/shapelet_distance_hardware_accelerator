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

#include "profiling_aux.h"

// Returns a new shapelet_profiling instance
// The inputs are an oversized buffer and the actual shapelet length
Shapelet_profiling profiling_init_shapelet(numeric_type **shapelet_values_buffer, uint16_t shapelet_len, numeric_type **shapelet_values){
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
    
        (*shapelet_array)[i] = profiling_init_shapelet(&shapelet_values_buffer, shapelet_len, &shapelet_values);
    }
    
    free(shapelet_values_buffer);
    free(shapelet_buffer);
}

// Distance from a shapelet to an entire time-series
numeric_type profiling_shapelet_ts_distance(Shapelet_profiling *normalized_shapelet, const Timeseries *time_series){
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
numeric_type **profiling_transform_dataset(Timeseries *T, uint16_t num_ts, Shapelet_profiling *normalized_shapelets, uint16_t num_shapelets){
    numeric_type **transformed_data;
    
    transformed_data = safe_alloc(num_ts * sizeof(*transformed_data));
    for (uint16_t i = 0; i < num_ts; i++){
        transformed_data[i] = safe_alloc(num_shapelets * sizeof(**transformed_data));
    }
    
    for (uint16_t i = 0; i < num_ts; i++){
        for (uint16_t j = 0; j < num_shapelets; j++){
            transformed_data[i][j] = profiling_shapelet_ts_distance(&normalized_shapelets[j], &T[i]);
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
    for(int i=0; i < size; i++){
        printf("%g ", vec[i]);
    }
    printf("\n");
}

