#include "shapelet_transform.h"
#include <stdio.h>

int main(int argc, char *argv[]){
    unsigned int k, num_ts;
    //Timeseries T[NUM_SERIES];
    Timeseries *T;
    char * infilename, *outfilename;
    
    // Get filenames and k from argv
    if(argc < 4){
        printf("Please use: %s {path_to_dataset} {output_csv} {k_best}\n", argv[0]);
        exit(-1);
    }
    infilename = argv[1];
    outfilename = argv[2];
    k = atoi(argv[3]);
    if(k < 0){
        printf("Error: k must be greater than zero\n");
        exit(-1);
    }
    // Load dataset and hold number of time-series loaded
    num_ts = read_train_dataset(infilename, &T);
    
    // Check dataset loading
    for(unsigned int i = 0; i < num_ts; i++)
        printf("[ TS: %u]\nfirst: %g, last: %g, class: %u\n", i,  T[i].values[0], T[i].values[T[i].length - 1], T[i].class);
    
    // Shapelet *k_best = malloc(k * sizeof(*k_best));

    // k_best = multi_thread_shapelet_cached_selection(T, num_ts, 3, 152, k, 16);

    // shapelet_set_to_csv(k_best, k, T, outfilename);
    
    for (unsigned int i = 0; i < num_ts; i++){
        free(T[i].values);
    }
    free(T);
    
    // free(k_best);

    return 0;
}