
#include "shapelet_transform.h"
#include <stdio.h>


int main(int argc, char *argv[]){
    char *hw_distances_filename, *sw_distances_filename, *dataset_filename;
    FILE *hw_file_descriptor, *sw_file_descriptor;
    const uint8_t HEX_BSIZE = 10;
    char hex_buffer[HEX_BSIZE];
    Timeseries *T;
    uint16_t num_ts;

    float *hw_distances_array, *sw_distances_array;
    uint32_t uint_distance;
    float float_distance, fstat;
    
    // Get filenames and k from argv
    if(argc != 4){
        printf("Please use: %s {sw_distances_filename} {hw_distances_filename} {dataset_filename}\n", argv[0]);
        exit(-1);
    }
    
    // Get number of time-series (same as number of distances) and distances filename from terminal arguments
    sw_distances_filename = argv[1];
    hw_distances_filename = argv[2];
    dataset_filename = argv[3];
    
    // Load dataset and hold number of time-series loaded
    num_ts = read_train_dataset(dataset_filename, &T);
    printf("Number of time-series (and distances): %d\n", num_ts);
    
    sw_distances_array = safe_alloc(num_ts * sizeof(*hw_distances_array));
    hw_distances_array = safe_alloc(num_ts * sizeof(*hw_distances_array));
    
    //// Load software-generated distances
    sw_file_descriptor = fopen(sw_distances_filename, "r");
    if (sw_file_descriptor == NULL){
        perror("Error opening software-generated distances file:");
        exit(errno);
    }
    
    // Read num_ts hardware-generated distances
    for(uint16_t i = 0; i < num_ts; i++){
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
        
        //printf("%08x, %g\n", uint_distance, float_distance);
        
        sw_distances_array[i] = float_distance;
    }
    close(sw_file_descriptor);
    
    fstat = bin_f_statistic(sw_distances_array, T, num_ts);
    printf("Software-generated F-statistic: %g\n", fstat);
    free(sw_distances_array);
    
    //// Load hardware-generated distances
    // hw_file_descriptor = fopen(hw_distances_filename, "r");
    // if (hw_file_descriptor == NULL){
        // perror("Error opening hardware-generated distances file:");
        // exit(errno);
    // }
    
    // // Read num_ts hardware-generated distances
    // for(uint16_t i = 0; i < num_ts; i++){
        // // Load HEX_BSIZE chars from file to buffer
        // if(!fgets(hex_buffer, HEX_BSIZE, hw_file_descriptor)){
            // perror("Error reading hex distance: ");
            // exit(errno);
        // }
        
        // // If HEX_BSIZE is enought to read a line of the dataset, the '\n' will be found in hex_buffer, else exit
        // if (!strchr(hex_buffer, '\n')) {
            // printf("\nHEX_BSIZE is not larger than number of characters in a line\n");
            // exit(-1);
        // }
        
        // sscanf(hex_buffer, "%08x", &uint_distance);
        // union{
            // float f;
            // uint32_t u;
        // } f2u;
        // f2u.u = uint_distance;
        // float_distance = f2u.f;
        
        // //printf("%08x, %g\n", uint_distance, float_distance);
        
        // hw_distances_array[i] = float_distance;
    // }
    // close(hw_file_descriptor);
    
    // fstat = bin_f_statistic(hw_distances_array, T, num_ts);
    // printf("Hardware-generated F-statistic: %g\n", fstat);
    // free(hw_distances_array);
   
    return 0;
}