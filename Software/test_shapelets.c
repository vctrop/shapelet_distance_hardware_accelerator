// 
#include "shapelet_transform.h"
#include <stdio.h>

int main(int argc, char *argv[]){
    float subsequence_1[] = {1.0, 2.0, 0.0};
    float subsequence_2[] = {0.9, 2.0, 4.0};
    double distance;
    float *normalized_subseq;
    int i;
    
    // Display single and double precision floating point sizes
    fp_sizes();
    
    // Euclidean distance calculation between sequences 1 and 2
    distance = fp_euclidean_distance(subsequence_1, subsequence_2, 3);
    printf("Euclidean distance is %lf\n", distance);
    
    // Normalize subsequence
    normalized_subseq = normalize_shapelet(subsequence_1, 3);
    for (i=0; i<3; i++)
        printf("%f ", normalized_subseq[i]);
    printf("\n");
    
    return 0;
}