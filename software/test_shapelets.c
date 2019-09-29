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
    int i;
    
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
    len_wise_distances = length_wise_distances(pivot_ts, target_ts, 3, 2);
    for(i = 0; i < (3 - 2 + 1); i++)
        printf("%.5lf ", len_wise_distances[i]);
    printf("\n");
    free(len_wise_distances);
    
    return 0;
}