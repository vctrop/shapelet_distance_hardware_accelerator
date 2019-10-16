// 
#include "shapelet_transform.h"
#include <stdio.h>


static inline double get_value(Shapelet *s, uint16_t j){
    return s->Ti[s->start_position + j];
}


void print_shapelets(Shapelet * S, size_t num_shapelets)
{
    for(int i=0; i < num_shapelets; i++)
    {
        printf("%dth Shapelet has length: %d, quality: %g \nValues from timseries %p:\t", i, S[i].length, S[i].quality, S[i].Ti); 
        for(int j = 0; j < S[i].length; j++)
            printf("%g ", get_value(&S[i], j));
        printf("\n\n");
    }
}


int main(int argc, char *argv[]){
    double subsequence_1[] = {1.0, 2.0, 2.0};
    double subsequence_2[] = {0.9, 2.0, 4.0};
    double time_series[][9] = {{2.0, 0.0, 3.0, 4.0, 0.0, 6.7, 2.2, 1.4, 4.1}, {5.0, 0.5, 3.5, 5.0, 5.0, 0.5, 3.5, 5.0, 3.0}};
    double pivot_ts[] = {2.0, 0.0, 3.0};
    double target_ts[] = {2.0, 1.0, 3.0};
    double distance, *len_wise_distances;
    double *normalized_subseq;
    unsigned int i, j, k=4, num_shapelets, shapelet_size, ts_size;
    Shapelet *shapelets_array = malloc(k * sizeof(Shapelet));
    

    //shapelets_array = shapelet_cached_selection(time_series, ts_class, 2, 4, 1, 2, 3);
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
    
    shapelet_size = 2;
    ts_size = 9;        
    num_shapelets = ts_size - shapelet_size + 1;  // 3
    shapelets_array =  malloc(num_shapelets * sizeof(Shapelet));
    for(i = 0; i < num_shapelets; i++){
        shapelets_array[i] = init_shapelet(time_series[0], i, shapelet_size);
        shapelets_array[i].quality = i + 0.1;
    }
    print_shapelets(shapelets_array, num_shapelets);

    printf("\nQuick sort of shapelets\n");
    qsort_shapelets(shapelets_array, num_shapelets);
    print_shapelets(shapelets_array, num_shapelets);
    shapelets_array = remove_self_similars(shapelets_array, &num_shapelets);
    printf("new shapelet number: %d\n", num_shapelets);
    print_shapelets(shapelets_array, num_shapelets);
    return 0;
}