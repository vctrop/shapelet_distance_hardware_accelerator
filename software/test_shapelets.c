// 
#include "shapelet_transform.h"
#include <stdio.h>

static inline double get_value(Shapelet *s, uint16_t j){
    return s->Ti[s->start_position + j];
}


void print_shapelets(Shapelet * S, size_t num_shapelets){
    for(int i=0; i < num_shapelets; i++)
    {
        printf("%dth Shapelet has length: %d, quality: %g \nValues from timseries %p:\t", i, S[i].length, S[i].quality, S[i].Ti); 
        for(int j = 0; j < S[i].length; j++)
            printf("%g ", get_value(&S[i], j));
        printf("\n\n");
    }
}


// Read the wafer train data into ts_array, with 1000 time-series and 152 data points per time series 
void read_wafer(Timeseries *ts_array, uint16_t length){
    char filename[] = "data/Wafer/Wafer_TRAIN.csv";
    FILE *file_descriptor;
    char *field;
    uint8_t ts_class;
    const uint16_t ts_len = 152;
    const uint16_t TS_BSIZE = 1800;
    char time_series_buffer[TS_BSIZE];
    double ts_values[ts_len];
    
    // Reads csv file and keeps its address at file_descriptor
    file_descriptor = fopen(filename, "r");
    if (file_descriptor == NULL){
        perror("Error opening csv: );
        exit(errno);
    }
    
    for(uint16_t i = 0; i < length; i++){
        if(fgets(time_series_buffer, TS_BSIZE, file_descriptor)){
            perror("Error reading time series buffer: ");
            exit(errno);
        }
        
        // The first "ts_len" values are from the time series, and the next one is the ts class
        for(uint16_t j = 0; j < ts_len; j++){
            field = strtok(time_series_buffer, ",");
            ts_values[i] = atof(field);
        }
        field = strtok(time_series_buffer, ",");
        ts_class = atof(field);
        
        ts_array[i] = init_timeseries(ts_values, ts_class, ts_len);
    }
    
}


int main(int argc, char *argv[]){
    double subsequence_1[] = {1.0, 2.0, 2.0};
    double subsequence_2[] = {0.9, 2.0, 4.0};
    double time_series_values[][4] = {{2.0, 0.0, 3.0, 4.0}, { 0.5, 3.5, 5.0, 3.0}, {5.0, 3.5, 5.0, 5.0}, {6.7, 2.2, 1.4, 4.1}};
    double pivot_ts[] = {2.0, 0.0, 3.0};
    double target_ts[] = {2.0, 1.0, 3.0};
    double distance, *len_wise_distances;
    double *normalized_subseq;
    unsigned int i, j, k=4, num_shapelets, shapelet_size, ts_size;
    Shapelet *shapelets_array_1 = malloc(k * sizeof(Shapelet));
    Shapelet *shapelets_array_2 =  malloc(k*2 * sizeof(Shapelet));
    Shapelet *k_best = malloc(k * sizeof(*k_best));

    Timeseries T[4];
    T[0] = init_timeseries(time_series_values[0], 0, 4);
    T[1] = init_timeseries(time_series_values[1], 1, 4);
    T[2] = init_timeseries(time_series_values[2], 0, 4);
    T[3] = init_timeseries(time_series_values[3], 1, 4);
    
    k_best = shapelet_cached_selection(T, 4, 2, 3, k);
    print_shapelets(k_best, k);
    /*
    double measured_dis[] = {0, 0.285014, 0.361536, 0.0998164};
    double fstat = bin_f_statistic(measured_dis, T, 4);
    printf("fstat: %g\n", fstat);
    */
    //shapelets_array_1 = shapelet_cached_selection(time_series, ts_class, 2, 4, 1, 2, 3);
    // Euclidean distance calculation between sequences 1 and 2
    // distance = fp_euclidean_distance(subsequence_1, subsequence_2, 3);
    // printf("Euclidean distance is %lf\n", distance);
    
    // Normalize subsequence
    // normalized_subseq = normalize_shapelet(subsequence_1, 3);
    // for (i=0; i<3; i++)
        // printf("%f ", normalized_subseq[i]);
    // printf("\n");
    // free(normalized_subseq);
    
    // Shapelet to time-series distance computation
    // distance = shapelet_ts_distance(subsequence_1, 3, time_series, 4);
    // printf("Shapelet to TS distance = %.4lf\n", distance);
    
    // Distances from all (m - l + 1) shapelets of length l in the pivot time-series to the target time-series
    // len_wise_distances = length_wise_distances(pivot_ts, target_ts, 3, 2);
    // for(i = 0; i < (3 - 2 + 1); i++)
        // printf("%.5lf ", len_wise_distances[i]);
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