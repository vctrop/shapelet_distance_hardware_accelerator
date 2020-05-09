// Copyright GMicro UFSM 2020.
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

#include "shapelet_transform.h"
#include <stdio.h>
#include <unistd.h>


int main(int argc, char *argv[]){
    char *hw_distances_filename, *sw_distances_filename, *dataset_filename;
    FILE *hw_file_descriptor, *sw_file_descriptor;
    const uint8_t HEX_BSIZE = 15;
    char hex_buffer[HEX_BSIZE];
    Timeseries *T;
    uint16_t num_ts, shapelet_len, ts_len, shapelets_per_ts;

    float *hw_distances_array, *sw_distances_array;
    uint32_t uint_distance;
    float minimum_ts_distance;
    float float_distance, fstat;
    
    
    // Get filenames and k from argv
    if(argc != 5){
    printf("Please use: %s {SW distances filename} {HW distances filename} {dataset filename} {shapelet length}\n", argv[0]);
        exit(-1);
    }
    
    // Get number of time-series (same as number of distances) and distances filename from terminal arguments
    sw_distances_filename = argv[1];
    hw_distances_filename = argv[2];
    dataset_filename = argv[3];
    shapelet_len = (uint16_t) atoi(argv[4]);
    
    // Load dataset and hold number of time-series loaded
    num_ts = read_train_dataset(dataset_filename, &T);
    printf("Number of time-series (and distances): %d\n", num_ts);
    ts_len = T->length;
    shapelets_per_ts = ts_len - shapelet_len + 1;
    printf("Shapelets per ts: %d\n", shapelets_per_ts);
    
    sw_distances_array = safe_alloc(num_ts * sizeof(*hw_distances_array));
    hw_distances_array = safe_alloc(num_ts * sizeof(*hw_distances_array));
    
    //// LOAD SOFTWARE-GENERTED DISTANCES
    sw_file_descriptor = fopen(sw_distances_filename, "r");
    if (sw_file_descriptor == NULL){
        perror("Error opening software-generated distances file:");
        exit(errno);
    }
    
    // Read num_ts hardware-generated distances
    for(uint16_t i = 0; i < num_ts; i++){
        minimum_ts_distance = INFINITY;
        
        for (uint16_t j = 0; j < shapelets_per_ts; j++){
            // Load HEX_BSIZE chars from file to buffer
            if(!fgets(hex_buffer, HEX_BSIZE, sw_file_descriptor)){
                perror("Error reading hex distance: ");
                exit(errno);
            }
            
            // If HEX_BSIZE is enought to read a line of the dataset, the '\n' will be found in hex_buffer, else exit
            if (!strchr(hex_buffer, '\n')) {
                printf("\nHEX_BSIZE is not larger than number of characters in a line\n");
                exit(-1);
            }
            
            sscanf(hex_buffer, "%08x", &uint_distance);
            union{
                float f;
                uint32_t u;
            } f2u;
            f2u.u = uint_distance;
            float_distance = f2u.f;    
            //printf("float: %.5f\n", float_distance);
            
            if (float_distance < minimum_ts_distance){
                minimum_ts_distance = float_distance;
            }
            //printf("min: %.5f\n", minimum_ts_distance);
        }
        
        //printf("%.5f\n", minimum_ts_distance);
        
        sw_distances_array[i] = minimum_ts_distance;
    }
    
    fstat = bin_f_statistic(sw_distances_array, T, num_ts);
    free(sw_distances_array);
    printf("Software-generated F-statistic: %.6f\n", fstat);
    
    //// LOAD HARDWARE-GENERTED DISTANCES
    hw_file_descriptor = fopen(hw_distances_filename, "r");
    if (hw_file_descriptor == NULL){
        perror("Error opening hardware-generated distances file:");
        exit(errno);
    }
    
    // Read num_ts hardware-generated distances
    for(uint16_t i = 0; i < num_ts; i++){
        minimum_ts_distance = INFINITY;
        
        for (uint16_t j = 0; j < shapelets_per_ts; j++){
            // Load HEX_BSIZE chars from file to buffer
            if(!fgets(hex_buffer, HEX_BSIZE, hw_file_descriptor)){
                perror("Error reading hex distance: ");
                exit(errno);
            }
            
            //printf("%s", hex_buffer);
            
            // If HEX_BSIZE is enought to read a line of the dataset, the '\n' will be found in hex_buffer, else exit
            if (!strchr(hex_buffer, '\n')) {
                printf("\nHEX_BSIZE is not larger than number of characters in a line\n");
                // exit(-1);
            }
            
            sscanf(hex_buffer, "%08x", &uint_distance);
            union{
                float f;
                uint32_t u;
            } f2u;
            f2u.u = uint_distance;
            float_distance = f2u.f;    
            //printf("float: %.5f\n", float_distance);
            
            if (float_distance < minimum_ts_distance){
                minimum_ts_distance = float_distance;
            }
            //printf("min: %.5f\n", minimum_ts_distance);
        }
        
        //printf("%.5f\n", minimum_ts_distance);
        
        hw_distances_array[i] = minimum_ts_distance;
    }
    
    fstat = bin_f_statistic(hw_distances_array, T, num_ts);
    free(hw_distances_array);
    printf("Hardware-generated F-statistic: %.6f\n", fstat);
    
    close(sw_file_descriptor);
    close(hw_file_descriptor);
    
    return 0;
}