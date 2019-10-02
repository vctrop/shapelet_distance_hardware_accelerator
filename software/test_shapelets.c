// 
#include "shapelet_transform.h"
#include <stdio.h>

int main(int argc, char *argv[]){
    double subsequence_1[] = {1.0, 2.0, 2.0};
    double subsequence_2[] = {0.9, 2.0, 4.0};
    double time_series[] = {2.0, 0.0, 3.0, 4.0};
    double pivot_ts[] = {2.0, 0.0, 3.0};
    double target_ts[] = {2.0, 1.0, 3.0};
    double distance, *len_wise_distances;
    double *normalized_subseq;
    unsigned int i, j, num_shapelets, shapelet_size, ts_size;
    Shapelet **shapelets_array;
    
    // Display single and double precision floating point sizes for the current system
    //fp_sizes();
    
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
    ts_size = 4;        
    num_shapelets = ts_size - shapelet_size + 1;  // 3
    shapelets_array = (Shapelet **) malloc(num_shapelets * sizeof(Shapelet *));
    for(i = 0; i < num_shapelets; i++){
        shapelets_array[i] = assemble_shapelet(time_series, i, shapelet_size);
        shapelets_array[i] -> quality = i + 0.1;
        printf("Shapelet length is %d, quality is %g \n", shapelets_array[i]->length, shapelets_array[i]->quality); 
        for(j = 0; j < shapelets_array[i]->length; j++)
            printf("%g ", shapelets_array[i]->values[j]);
        printf("\n");
    }
    
    printf("\nQuick sort of shapelets\n");
    qsort_shapelets(shapelets_array, num_shapelets);
    for(i = 0; i < num_shapelets; i++){
        printf("Shapelet length is %d, quality is %g \n", shapelets_array[i]->length, shapelets_array[i]->quality); 
        for(j = 0; j < shapelets_array[i]->length; j++)
            printf("%g ", shapelets_array[i]->values[j]);
        printf("\n");
    }
    
    return 0;
}