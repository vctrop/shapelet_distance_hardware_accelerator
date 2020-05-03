
#include "shapelet_transform.h"
#include <stdio.h>


int main(int argc, char *argv[]){
    char *errors_filename, *dataset_filename;
    FILE *errors_file_descriptor;
    const uint8_t HEX_BSIZE = 8 + 1;
    char hex_buffer[HEX_BSIZE];
    Timeseries *T;
    uint16_t num_ts;

    float *errors_array;
    uint32_t uint_error;
    float float_error;
    
    // Get filenames and k from argv
    if(argc != 3){
        printf("Please use: %s {errors_filename} {used_dataset_filename}\n", argv[0]);
        exit(-1);
    }
    
    // Get number of time-series (same as number of errors) and errors filename from terminal arguments
    errors_filename = argv[1];
    dataset_filename = argv[2];
    
    errors_file_descriptor = fopen(errors_filename, "r");
    if (errors_file_descriptor == NULL){
        perror("Error opening errors file:");
        exit(errno);
    }
    
    // Load dataset and hold number of time-series loaded
    num_ts = read_train_dataset(dataset_filename, &T);
    printf("Number of time-series (and errors): %d\n", num_ts);
    
    // Load errors array from file
    errors_array = safe_alloc(num_ts * sizeof(*errors_array));
    
    // Read all num_ts time-series from the dataset
    for(uint16_t i = 0; i < num_ts; i++){
        // Load HEX_BSIZE chars from file to buffer
        if(!fgets(hex_buffer, HEX_BSIZE, errors_file_descriptor)){
            perror("Error reading hex error: ");
            exit(errno);
        }
        
        // If HEX_BSIZE is enought to read a line of the dataset, the '\n' will be found in hex_buffer, else exit
        if (!strchr(hex_buffer, '\n')) {
            printf("\nHEX_BSIZE is not larger than number of characters in a line\n");
            exit(-1);
        }
        
        sscanf(hex_buffer, "%08x", &uint_error);
        union{
            float f;
            uint32_t u;
        } f2u;
        f2u.u = uint_error;
        float_error = f2u.f;
        
        printf("%08x, %g\n", uint_error, float_error);
        
        errors_array[i] = float_error;
    }
    
    free(errors_array);
   
    return 0;
}