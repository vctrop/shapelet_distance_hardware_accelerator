//
// september, 2019

#include "shapelet_transform.h"

// Floating-point size displaying
void fp_sizes(void){
    printf("Float has %d bytes in this system\n", sizeof(float));
    printf("Double has %d bytes in this system\n", sizeof(double));
}


// Shapelet normalization (FREE RETURNED POINTER AFTER USAGE)
double *normalize_shapelet(double *shapelet, uint16_t size){
    double squares_sum, absolute_value;
    double *normalized_shapelet;
    uint16_t i;
    
    normalized_shapelet = (double*) malloc(size * sizeof(double));
    if (normalized_shapelet == NULL){
        perror("Error on normalized shapelet allocation:");
        exit(-1);
    }
    else{
        // Compute shapelet absolute value
        squares_sum = 0.0;
        for (i=0; i<size; i++)
            squares_sum += pow(shapelet[i], 2);
        absolute_value = sqrt(squares_sum);
        //printf("Absolute value is %lf\n", absolute_value);
        
        // Compute normalized shapelet values
        for (i=0; i<size; i++)
            normalized_shapelet[i] = shapelet[i]/absolute_value;
    }
    
    return normalized_shapelet;
}


// Fixed-point euclidean distance
// uint64_t fixp_euclidean_distance(uint32_t *pivot_shapelet, uint32_t *target_shapelet, uint16_t size){}


// Floating-point euclidean distance
double fp_euclidean_distance(double *pivot_shapelet, double *target_shapelet, uint16_t size){
    uint16_t i;
    double partial_distance, total_distance;
    
    total_distance = 0.0;
    for (i = 0; i < size; i++){
        partial_distance = pow(pivot_shapelet[i] - target_shapelet[i],2);
        total_distance += partial_distance;
    }
    
    return total_distance;
}


// Returns pointer to new shapelet of a given size in a given time-series position (FREE RETURNED POINTER AFTER USAGE)
double *assemble_shapelet(double *time_series, uint16_t shapelet_position, uint16_t shapelet_len){
    uint16_t i;
    double *shapelet;
   
    shapelet = (double*) malloc(shapelet_len * sizeof(double));
    
    // Assemble shapelet by accessing time series positions
    for(i = shapelet_position; i < (shapelet_position + shapelet_len); i++){
        //printf("%.4f ", time_series[i]);
        shapelet[i - shapelet_position] = time_series[i];
    }
    //printf("\n");
    
    return shapelet;
}


// Distance from a shapelet to an entire time-series
double shapelet_ts_distance(double *pivot_shapelet, uint16_t shapelet_len, double *time_series, uint16_t ts_len){
    double shapelet_distance, minimum_distance = INFINITY;
    double *ts_shapelet;
    double *norm_pivot_shapelet, *norm_ts_shapelet;
    uint16_t i, j, num_shapelets;
    
    num_shapelets = ts_len - shapelet_len + 1;                          // number of shapelets of length "shapelet_len" in time_series
    // Loops over shapelets in the time-series
    for (i=0; i<num_shapelets; i++){
        // Assemble shapelet i
        ts_shapelet = assemble_shapelet(time_series, i, shapelet_len);
        
        // Normalize pivot and time-series shapelets
        norm_pivot_shapelet = normalize_shapelet(pivot_shapelet, shapelet_len);
        norm_ts_shapelet = normalize_shapelet(ts_shapelet, shapelet_len);
        free(ts_shapelet);
        
        // Compute shapelet-shapelet distance
        shapelet_distance = fp_euclidean_distance(norm_pivot_shapelet, norm_ts_shapelet, shapelet_len);
        printf("Distance from pivot shapelet to %dth time series shapelet is %.5f\n", i, shapelet_distance); 
        free(norm_pivot_shapelet);
        free(norm_ts_shapelet);
        
        // Keep the minimum distance between the pivot shapelet and all the time-series shapelets
        if (shapelet_distance < minimum_distance)
            minimum_distance = shapelet_distance;
    }
    
    return minimum_distance;
}


// [HARDWARE-friendly, reducing memory transfer] Distances from all the "shapelet_len"-sized shapelets in a time series to another time series (FREE RETURNED POINTER AFTER USAGE)
double *length_wise_distances(double *pivot_ts, double *target_ts, uint16_t ts_len, uint16_t shapelet_len){
    uint16_t i, num_shapelets;
    double *pivot_shapelet, *shapelets_target_distances, distance;
    
    if (shapelet_len > ts_len){
        perror("Shapelet length greater than time series length");
        exit(-1);
    }
    
    num_shapelets = (ts_len - shapelet_len + 1);
    shapelets_target_distances = (double*) malloc(num_shapelets * sizeof(double));           // Array of all "shapelet_len"-sized distances to a given time series
    
    for(i = 0; i < num_shapelets; i++){
        pivot_shapelet = assemble_shapelet(pivot_ts, i, shapelet_len);
        distance = shapelet_ts_distance(pivot_shapelet, shapelet_len, target_ts, ts_len);
        shapelets_target_distances[i] = distance;
        printf("Distance from shapelet %d of pivot TS to target TS: %.5lf \n", i, distance);
        free(pivot_shapelet);
    }
    
    return shapelets_target_distances;
}

// F-Statistic based on distance measures and associated classes
double f_statistic(double *measured_distances, uint16_t num_of_ts, uint8_t *ts_classes){
    double f_stat;
    const uint8_t num_classes = 2;
    double total_average, class_averages_sum, *class_averages, *class_counts;
    double partial_individual_sum, total_individual_sum;
    double **distances_by_class;
    uint8_t i, j;
    
    // Split distances by class and calculate averages
    for(i = 0; i < ; i++){
        
        // Calc class averages
        
        // Calc total averages
        
    }
    
    // Calculate individual sums
    
    f_stat = (class_averages_sum/(num_classes - 1))/(total_individual_sum/(num_of_ts - num_classes);
    
    return f_stat;
}


// SHAPELET CACHED SELECTION (from algorithm 3 in "Classification of time series by shapelet transformation", Hills et al., 2013)
// Given a set T of time series attatched to labels, extract shapelets exhaustively from min to max lengths, keeping only the k best shapelets according to some criteria 
// (FREE ALL k RETURNED POINTERS AFTER USAGE)
double **shapelet_cached_selection(double **T, uint8_t *ts_classes, uint16_t num_of_ts, uint16_t ts_len, uint16_t min, uint16_t max, uint16_t k){
    uint16_t i, l, j1, j2,  current_len, shapelets_index;
    uint32_t ,num_shapelets, total_num_shapelets;
    double **k_shapelets, **ts_shapelets, shapelet_quality;
    //double **shapelet_candidates;
    double *shapelet_candidate;
    double *shapelet_distances;
    
    if (min > max){
        perror("Min greater than max");
        exit(-1);
    }

    k_shapelets = (double**) malloc(k*sizeof(double*));
    
    // total number of shapelets in each T[i] (TODO: implement analytically)
    total_num_shapelets = 0;
    for (l = min; l <= max; l++)
        total_num_shapelets += ts_len - l + 1;
    
    // For each time-series T[i] in T
    for (i = 0; i < num_of_ts; i++){
        ts_shapelets = (double**) malloc(total_num_shapelets * sizeof(double*));
        shapelets_index = 0;
        // For each length between min and max
        for (l = min; l <= max; l++, shapelets_index++){ 
            //shapelet_candidates = generate_shapelet_candidates(T[i], ts_len, l);                              // The original algoritm generates an array with all normalized shapelet candidates
            num_shapelets = ts_len - l + 1;                                                                     // Number of shapelets of lenght l in T[i]
            
            // For each shapelet of the given length
            for (j1 = 0; j1 < num_shapelets; j1++){
                shapelet_candidate = assemble_shapelet(T[i], j1, l);                                            // Assemble each shapelet on the fly, instead of keeping them in a matrix
                shapelet_distances = (double*) malloc(num_of_ts * sizeof(double));
                // Calculate distances from current shapelet candidate to each time series in T, 
                for (j2 = 0; j2 < num_of_ts; j2++){
                    //shapelet_distances[j2] = shapelet_ts_distance(shapelet_candidates[j1], l, T[j2], ts_len);
                    shapelet_distances[j2] = shapelet_ts_distance(shapelet_candidate, l, T[j2], ts_len);
                }
                
                // F-Statistic as shapelet quality measure
                shapelet_quality = f_statistic(shapelet_distances, ts_classes);
                
                // Allocate space for shapelets and distance measures
                ts_shapelets[shapelets_index] = (double*) malloc((l+1) * sizeof(double));
                
                // Store every shapelet of T[i] with its quality measure 
                for (j2 = 0; j2 < l; j2++){
                    //ts_shapelets[shapelets_index][j2] = shapelet_candidates[j1][j2];
                    ts_shapelets[shapelets_index][j2] = shapelet_candidate[j2];
                }
                ts_shapelets[shapelets_index][l] = shapelet_quality;
                
                //free(shapelet_candidates[j1]);
                free(shapelet_candidate);
                free(shapelet_distances);
            }         
            //free(shapelet_candidates);            
        }  // Here all shapelets from T[i] should have been stored together with its quality measures in ts_shapelets                                                             
        
        // Sort shapelets by quality
        
        // Remove self similar shapelets
        
        // Merge ts_shapelets with k_shapelets and keep only best k shapelets
        
        // FREE ALL total_num_shapelets TS SHAPELETS
        free(ts_shapelets);
    }
    
    return k_shapelets;
}


// CACHED SELECTION SUPPORT FUNCTIONS
// [NOT USED NOR TESTED] Generate set of all normalized candidate shapelets of a specific length (FREE ALL "num_shapelets" RETURNED POINTERS AFTER USAGE)
// double **generate_shapelet_candidates(double *time_series, uint16_t ts_len, uint16_t shapelet_len){
    // uint16_t i, num_shapelets;
    // double **shapelets;

    // if (shapelet_len > ts_len){
        // perror("Shapelet length larger than time-series length");
        // exit(-1);
    // }
    
    // num_shapelets = ts_len - shapelet_len + 1;
    // shapelets = (double**) malloc(num_shapelets * sizeof(double*));
    // for (i = 0; i < num_shapelets; i++)
        // shapelets[i] = assemble_shapelet(time_series, i, shapelet_len);
    
    // return shapelets;     
// }

// Remove self similar shapelets (shapelets with overlapping indices)
// double *remove_self_similars(){}


