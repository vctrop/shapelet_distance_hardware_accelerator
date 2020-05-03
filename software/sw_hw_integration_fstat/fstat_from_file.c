
#include "shapelet_transform.h"
#include <stdio.h>


int main(int argc, char *argv[]){
    char *distances_filename, *dataset_filename;
    FILE *file_descriptor;
    const uint8_t HEX_BSIZE = 8 + 1;
    char hex_buffer[HEX_BSIZE];
    Timeseries *T;
    uint16_t num_ts;

    float *distances_array;
    uint32_t uint_distance;
    float float_distance, fstat;
    
    // Get filenames and k from argv
    if(argc != 3){
        printf("Please use: %s {distances_filename} {used_dataset_filename}\n", argv[0]);
        exit(-1);
    }
    
    // Get number of time-series (same as number of distances) and distances filename from terminal arguments
    distances_filename = argv[1];
    dataset_filename = argv[2];
    
    file_descriptor = fopen(distances_filename, "r");
    if (file_descriptor == NULL){
        perror("Error opening distances file:");
        exit(errno);
    }
    
    // Load dataset and hold number of time-series loaded
    num_ts = read_train_dataset(dataset_filename, &T);
    printf("Number of time-series (and distances): %d\n", num_ts);
    
    // Load distances array from file
    distances_array = safe_alloc(num_ts * sizeof(*distances_array));
    
    // Read all num_ts time-series from the dataset
    for(uint16_t i = 0; i < num_ts; i++){
        // Load HEX_BSIZE chars from file to buffer
        if(!fgets(hex_buffer, HEX_BSIZE, file_descriptor)){
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
        
        printf("%08x, %g\n", uint_distance, float_distance);
        
        distances_array[i] = float_distance;
    }
    
    fstat = bin_f_statistic(distances_array, T, num_ts);
    printf("F-statistic: %g\n", fstat);
    
    free(distances_array);
   
    return 0;
}