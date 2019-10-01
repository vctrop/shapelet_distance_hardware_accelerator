//
// september, 2019

#include "shapelet_transform.h"

// Floating-point size displaying
void fp_sizes(void){
    printf("Float has %ld bytes in this system\n", sizeof(float));
    printf("Double has %ld bytes in this system\n", sizeof(double));
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
Shapelet *assemble_shapelet(double *time_series, uint16_t shapelet_position, uint16_t shapelet_len){
    uint16_t i;
    Shapelet *shapelet; 

    // Allocates structure and array value memory 
    shapelet = (Shapelet*) malloc(sizeof(Shapelet));
    shapelet->values = (double *) malloc(shapelet_len * sizeof(double));
    
    shapelet->values = memcpy(shapelet->values, &time_series[shapelet_position], shapelet_len * sizeof(double));
    shapelet->quality = 0;
    shapelet->lenght = shapelet_len;
    // Assemble shapelet by accessing time series positions
    for(i = shapelet_position; i < (shapelet_position + shapelet_len); i++){
        printf("ts: %g\t sp: %g\n", time_series[i], shapelet->values[i - shapelet_position]);
        //shapelet[i - shapelet_position] = time_series[i];
    }
    printf("\n");
    
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
double f_statistic(double *measured_distances, uint8_t *ts_classes, uint16_t num_of_ts, uint8_t num_classes){
    double f_stat;
    double total_dists_sum, total_dists_average, *class_dist_sums, *class_dist_averages;
    double final_averages_sum, final_individual_sum;
    double **distances_by_class;
    uint16_t *members_per_class, *class_wise_counter;
    uint16_t i, j;
    uint8_t class;
    
    // Allocate memory for sums and averages
    class_dist_sums = (double*) malloc(num_classes * sizeof(double));
    class_dist_averages = (double*) malloc(num_classes * sizeof(double));
    
    // Allocate the number of members per class and class-wise counter
    members_per_class = (uint16_t*) malloc(num_classes * sizeof(uint16_t));
    class_wise_counter = (uint16_t*) malloc(num_classes * sizeof(uint16_t));
    
    // Initialize class-dependent values
    for(i = 0; i < num_classes; i++){
        members_per_class[i] = 0;
        class_wise_counter[i] = 0;
        class_dist_sums[i] = 0.0;
    }
        
    // Count number of members from each class
    for (i = 0; i < num_of_ts; i++){
        class = ts_classes[i];
        members_per_class[class]++;
    }
    
    // Allocate the splitted distances by class
    distances_by_class = (double**) malloc(num_classes * sizeof(double*));
    for (i = 0; i < num_classes; i++)
        distances_by_class[i] = (double*) malloc(members_per_class[i] * sizeof(double));
    
    total_dists_sum = 0.0;
    // Split distances by class and calculate sums
    for(i = 0; i < num_of_ts; i++){
        class = ts_classes[i];
        distances_by_class[class][class_wise_counter[class]] = measured_distances[i];
        class_wise_counter[class]++;
        
        // Total and class-wise sums
        class_dist_sums[class] += measured_distances[i];
        total_dists_sum += measured_distances[i];
    }
    
    // Calculate total and class-wise averages
    total_dists_average = total_dists_sum/num_of_ts;
    for(i = 0; i < num_classes; i++)
        class_dist_averages[i] = class_dist_sums[i]/members_per_class[i];
    
    // Calculate final averages sum
    final_averages_sum = 0.0;
    for(i = 0; i < num_classes; i++)
        final_averages_sum += pow((class_dist_averages[i] - total_dists_average),2);
    
    // Calculate final individual sum
    final_individual_sum = 0.0;
    for(i = 0; i < num_classes; i++){
        for(j = 0; j < members_per_class[i]; j++)
            final_individual_sum += pow((distances_by_class[i][j] - class_dist_averages[i]),2);
    }
    
    // Free allocated memory
    free(class_dist_averages);
    free(class_dist_sums);
    free(members_per_class);
    free(class_wise_counter);
    for (i = 0; i < num_classes; i++)
        free(distances_by_class[i]);
    free(distances_by_class);
    
    // Calculate F-Statistic
    f_stat = (final_averages_sum/(num_classes - 1))/(final_individual_sum/(num_of_ts - num_classes));
    
    return f_stat;
}


// SHAPELET CACHED SELECTION (from algorithm 3 in "Classification of time series by shapelet transformation", Hills et al., 2013)
// Given a set T of time series attatched to labels, extract shapelets exhaustively from min to max lengths, keeping only the k best shapelets according to some criteria 
// (FREE ALL k RETURNED POINTERS AFTER USAGE)
Shapelet *shapelet_cached_selection(double **T, uint8_t *ts_classes, uint16_t num_of_ts, uint16_t ts_len, uint16_t min, uint16_t max, uint16_t k){
    uint16_t i, l, j1, j2,  current_len, shapelets_index;
    uint32_t num_shapelets, total_num_shapelets;
    Shapelet *k_shapelets, *ts_shapelets;
    Shapelet *shapelet_candidate;
    double *shapelet_distances;
    double shapelet_quality;
    
    if (min > max){
        perror("Min greater than max");
        exit(-1);
    }

    k_shapelets = (Shapelet *) malloc(k*sizeof(Shapelet));
    
    // total number of shapelets in each T[i] (TODO: implement analytically)
    total_num_shapelets = 0;
    for (l = min; l <= max; l++)
        total_num_shapelets += ts_len - l + 1;
    
    // For each time-series T[i] in T
    for (i = 0; i < num_of_ts; i++){
        ts_shapelets = (Shapelet *) malloc(total_num_shapelets * sizeof(Shapelet *));
        shapelets_index = 0;
        // For each length between min and max
        for (l = min; l <= max; l++, shapelets_index++){ 
            num_shapelets = ts_len - l + 1;                                                                     // Number of shapelets of lenght l in T[i]
            
            // For each shapelet of the given length
            for (j1 = 0; j1 < num_shapelets; j1++){
                shapelet_candidate = assemble_shapelet(T[i], j1, l);                                            // Assemble each shapelet on the fly, instead of keeping them in a matrix
                shapelet_distances = (double*) malloc(num_of_ts * sizeof(double));
                // Calculate distances from current shapelet candidate to each time series in T, 
                for (j2 = 0; j2 < num_of_ts; j2++){
                    shapelet_distances[j2] = shapelet_ts_distance(shapelet_candidate->values, l, T[j2], ts_len);
                }
                
                // F-Statistic as shapelet quality measure
                shapelet_candidate->quality = f_statistic(shapelet_distances, ts_classes, num_of_ts, 2);
                free(shapelet_distances);   //shapelet_distances is only used to measure quality

                // Store every shapelet of T[i] with its quality measure and length in the format [quality, length, shapelet] with shapelet = [s1, s2, ..., sl] 
                ts_shapelets[shapelets_index] = *shapelet_candidate;
            }         
        }  // Here all shapelets from T[i] should have been stored together with its quality measures in ts_shapelets                                                             
        
        // Sort shapelets by quality
        
        // Remove self similar shapelets
        
        // Merge ts_shapelets with k_shapelets and keep only best k shapelets
        
        // TODO: FREE ALL total_num_shapelets TS SHAPELETS
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

// Compare shapelets quality measures for sorting with qsort()
int compare_shapelets(const void *shapelet_1, const void *shapelet_2){
    if (((Shapelet *) shapelet_1)->quality > ((Shapelet *) shapelet_2)->quality)
        return 1;
    else if (((Shapelet *) shapelet_1)->quality < ((Shapelet *)shapelet_2)->quality)
        return -1;
    else
        return 0;
}


// Apply quick sort in a set of shapelets, ordering by quality measure
void qsort_shapelets(Shapelet *shapelet_set, uint16_t size){
    qsort((void *) shapelet_set, (size_t) size, sizeof(Shapelet *), compare_shapelets);
}

// Remove self similar shapelets (shapelets with overlapping indices)
// double *remove_self_similars(){}


