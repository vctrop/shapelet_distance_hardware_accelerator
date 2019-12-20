// 
#include "shapelet_transform.h"
#include <stdio.h>

#define TS_LEN 152
#define NUM_SERIES 1000

// Read the wafer train data into ts_array, with 1000 time-series and 152 data points per time series
// Free all float arrays from ts_array
void read_wafer_train(char * filename, Timeseries *ts_array, uint16_t length){
    //char filename[] = "data/Wafer/Wafer_TRAIN.csv";
    FILE *file_descriptor;
    char *field;
    uint8_t ts_class;
    const uint16_t TS_BSIZE = 2000;
    char time_series_buffer[TS_BSIZE];
    numeric_type *ts_values;
    
    // Reads csv file and keeps its address at file_descriptor
    file_descriptor = fopen(filename, "r");
    if (file_descriptor == NULL){
        perror("Error opening csv: ");
        exit(errno);
    }
    
    for(uint16_t i = 0; i < length; i++){
        if(!fgets(time_series_buffer, TS_BSIZE, file_descriptor)){
            perror("Error reading time series buffer: ");
            exit(errno);
        }
        else{
            // The first "TS_LEN" values are from the time series, and the next one is the ts class
            field = strtok(time_series_buffer, ",");
            //printf("TIME-SERIES %u\n %s\t",i, field);
            
            ts_values = (numeric_type *) malloc (TS_LEN * sizeof(*ts_values));
            
            #ifdef USE_FLOAT
            ts_values[0] = atof(field);
            
            for(uint16_t j = 1; j < TS_LEN; j++){
                field = strtok(NULL, ",");
                //printf("%s\t", field);
                ts_values[j] = atof(field);
            }
            
            #else
            ts_values[0] = fixedpt_fromfloat(atof(field));
            
            for(uint16_t j = 1; j < TS_LEN; j++){
                field = strtok(NULL, ",");
                //printf("%s\t", field);
                ts_values[j] = fixedpt_fromfloat(atof(field));
            }
            #endif    
            
            field = strtok(NULL, ",");
            if (field == NULL){
                perror("\nError in class field: ");
                exit(errno);
            }
            // Treats class -1 as 0
            ts_class = (uint8_t) (atoi(field) != -1);
            //printf("Class = %u\n", ts_class);
            
            ts_array[i] = init_timeseries(ts_values, ts_class, TS_LEN);
            
        }
    }
    
}


void print_array(numeric_type * vec, size_t size){
    for(int i=0; i < size; i++)
        printf("%g ", vec[i]);
    printf("\n");
}


int main(int argc, char *argv[]){
    unsigned int k;
    Timeseries T[NUM_SERIES];
    char * filename;
    // get file name passed in argv
    if(argc < 3){
        printf("Please use: %s {path_to_csv} {k_best}\n", argv[0]);
        exit(-1);
    }
    filename = argv[1];
    k=atoi(argv[2]);
    if(k < 0){          //maybe check for a upper bound? 
        printf("Invalid K!\n");
        exit(-1);
    }
    // Real-life dataset
    read_wafer_train(filename, T, NUM_SERIES);

    Shapelet *k_best = malloc(k * sizeof(*k_best));

    k_best = shapelet_cached_selection(T, NUM_SERIES, 3, 152, k);

    free(k_best);

    return 0;
}