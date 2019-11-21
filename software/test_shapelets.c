// 
#include "shapelet_transform.h"
#include <stdio.h>

#define TS_LEN 152
#define NUM_SERIES 1000



// Read the wafer train data into ts_array, with 1000 time-series and 152 data points per time series
// Free all float arrays from ts_array
void read_wafer_train(Timeseries *ts_array, uint16_t length){
    char filename[] = "data/Wafer/Wafer_TRAIN.csv";
    FILE *file_descriptor;
    char *field;
    uint8_t ts_class;
    const uint16_t TS_BSIZE = 2000;
    char time_series_buffer[TS_BSIZE];
    // float ts_values[TS_LEN];
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


int main(int argc, char *argv[]){
    // float subsequence_2[] = {0.9, 2.0, 4.0};
    // float subsequence_1[] = {1.0, 2.0, 2.0};
    // float pivot_ts[] = {2.0, 0.0, 3.0};
    // float target_ts[] = {2.0, 1.0, 3.0};
    // float distance, *len_wise_distances;
    // float *normalized_subseq;
    // Shapelet *shapelets_array_1 = malloc(k * sizeof(Shapelet));
    // Shapelet *shapelets_array_2 =  malloc(k*2 * sizeof(Shapelet));
    // unsigned int j, num_shapelets, shapelet_size;
    unsigned int i,  k;
    
    
    double time_series_values[NUM_SERIES][TS_LEN] = {{2.0, 0.0, 3.0, 4.0, 7.1, 4.2, 4.8, 8.9}, {0.5, 3.5, 5.0, 3.0, 1.3, 2.5, 8.9, 8.5}, {5.0, 3.5, 5.0, 5.0, 5.6, 5.2, 6.2, 6.0}, {6.7, 2.2, 1.4, 4.1, 3.1, 2.3, 4.2, 4.4},
                                                 {1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9}, {7.3, 7.2, 7.0, 6.9, 6.6, 6.3, 6.5, 5.3}, {2.3, 2.1, 2.0, 3.0, 4.0, 3.5, 3.3, 3.4}, {5.1, 5.6, 5.7, 5.1, 5.0, 4.2, 4.2, 0.0}};
    
    fixedpt time_series_values_fx[][4] = 
    {{fixedpt_rconst(2.0), fixedpt_rconst(0.0), fixedpt_rconst(3.0), fixedpt_rconst(4.0)},
    {fixedpt_rconst(0.5), fixedpt_rconst(3.5), fixedpt_rconst(5.0), fixedpt_rconst(3.0)},
    {fixedpt_rconst(5.0), fixedpt_rconst(3.5), fixedpt_rconst(5.0), fixedpt_rconst(5.0)},
    {fixedpt_rconst(6.7), fixedpt_rconst(2.2), fixedpt_rconst(1.4), fixedpt_rconst(4.1)}};
    

    
    // Real-life dataset
    Timeseries T[NUM_SERIES];
    
    
    read_wafer_train(T, NUM_SERIES);
    // for(i = 0; i < NUM_SERIES; i++){
        // #ifdef USE_FLOAT
        // printf("[ TS: %u]\nfirst: %g, last: %g, class: %u\n", i,  T[i].values[0], T[i].values[TS_LEN-1], T[i].class);
        // #else
        // printf("[TS: %u, class: %u] (first, last, class)\n", i, T[i].class);
        // fixedpt_print(T[i].values[0]);  fixedpt_print(T[i].values[TS_LEN-1]);
        // #endif
    // } 
    
    /*   
    Timeseries T[NUM_SERIES];
    for(int i =0; i < NUM_SERIES; i++)
    {
        T[i] = init_timeseries(time_series_values[i], i%2, TS_LEN);
        printf("[TS %d]:\t", i);
        for(int j = 0; j < TS_LEN; j++)
        {
            printf("%g ", T[i].values[j]);
        }
        printf("\n");
    }*/

    k=50;
    Shapelet *k_best = malloc(k * sizeof(*k_best));

    //k_best = multi_thread_shapelet_cached_selection(T, NUM_SERIES, 3, 10, k, 38);
    k_best = shapelet_cached_selection(T, NUM_SERIES, 3, 10, k);

    free(k_best);
    /*
    float measured_dis[] = {0, 0.285014, 0.361536, 0.0998164};
    float fstat = bin_f_statistic(measured_dis, T, 4);
    printf("fstat: %g\n", fstat);
    */
    //shapelets_array_1 = shapelet_cached_selection(time_series, ts_class, 2, 4, 1, 2, 3);
    // Euclidean distance calculation between sequences 1 and 2
    // distance = fp_euclidean_distance(subsequence_1, subsequence_2, 3);
    // printf("Euclidean distance is %lf\n", distance);
    
    // Normalize subsequence
    // for (i=0; i<3; i++)
        // printf("%f ", normalized_subseq[i]);
    // printf("\n");
    // free(normalized_subseq);
    
    // Shapelet to time-series distance computation
    // distance = shapelet_ts_distance(subsequence_1, 3, time_series, 4);
    // printf("Shapelet to TS distance = %.4lf\n", distance);
    
    // printf("\n");
    // free(len_wise_distances);

    /* tests qsort, self similars and merge
    shapelet_size = 2;
    ts_size = 9;        
    num_shapelets = ts_size - shapelet_size + 1;  // 3
    shapelets_array_1 =  malloc(num_shapelets * sizeof(Shapelet));
    for(i = 0; i < num_shapelets; i++){
        shapelets_array_1[i] = init_shapelet(time_series[0], i, shapelet_size);
        shapelets_array_1[i].quality = i*i + 0.1;
        shapelets_array_2[i] = init_shapelet(time_series[1], i, shapelet_size);
        shapelets_array_2[i].quality = i*i - 0.1;
    }
    print_shapelets(shapelets_array_1, num_shapelets);
    int num_shapelets2 = num_shapelets;

    printf("\nQuick sort of shapelets\n");
    qsort_shapelets(shapelets_array_1, num_shapelets);
    print_shapelets(shapelets_array_1, num_shapelets);
    printf("\n remove self similar\n");
    shapelets_array_1 = remove_self_similars(shapelets_array_1, &num_shapelets);
    printf("new shapelet number: %d\n", num_shapelets);
    print_shapelets(shapelets_array_1, num_shapelets);

    printf("\nQuick sort of shapelets\n");
    qsort_shapelets(shapelets_array_2, num_shapelets2);
    print_shapelets(shapelets_array_2, num_shapelets2);
    printf("\n remove self similar\n");
    shapelets_array_2 = remove_self_similars(shapelets_array_2, &num_shapelets2);
    printf("new shapelet number: %d\n", num_shapelets2);
    print_shapelets(shapelets_array_2, num_shapelets2);

    printf("\nMerging shapelets!\n");
    merge_shapelets(shapelets_array_1, num_shapelets, shapelets_array_2, num_shapelets2);
    print_shapelets(shapelets_array_1, num_shapelets);
    
    return 0;
    */
}