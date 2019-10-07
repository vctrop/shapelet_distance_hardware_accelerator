//
// september, 2019

#include "shapelet_transform.h"

// Floating-point size displaying
void fp_sizes(void){
    printf("Float has %ld bytes in this system\n", sizeof(float));
    printf("Double has %ld bytes in this system\n", sizeof(double));
}

// Returns pointer to new shapelet of a given size in a given time-series position (DESTROY THE RETURNED SHAPELET AFTER USAGE)
Shapelet init_shapelet(double *time_series, uint16_t shapelet_position, uint16_t shapelet_len){
    Shapelet shapelet; 
    shapelet.length = shapelet_len;
    shapelet.quality = 0;
    shapelet.start_position = shapelet_position;
    shapelet.Ti = time_series;
    return shapelet;
}


// Returns the j-th value of a shapelet
static inline double get_value(Shapelet *s, uint16_t j){
    return s->Ti[s->start_position + j];
}


// Normalizes the values of a given vector
void normalize_values(double *values, uint16_t length){
    double squares_sum, absolute_value;
    
    // Compute shapelet absolute value
    squares_sum = 0.0;
    for (uint16_t i = 0; i < length; i++)
        squares_sum += pow(values[i], 2);
    absolute_value = sqrt(squares_sum);
    //printf("Absolute value is %lf\n", absolute_value);

    // check for possible division by zero error
    if(absolute_value == 0)
    {
        return;
    }

    // Compute normalized shapelet values
    for (uint16_t i = 0; i < length; i++)
        values[i] = values[i] / absolute_value;
}


// Fixed-point euclidean distance
// uint64_t fixp_euclidean_distance(uint32_t *pivot_shapelet, uint32_t *target_shapelet, uint16_t size){}


// Floating-point euclidean distance
double fp_euclidean_distance(Shapelet *pivot_shapelet, Shapelet *target_shapelet){
    double total_distance;
    double *pivot_values, *target_values;

    if(pivot_shapelet->length != target_shapelet->length){
        perror("Error: different shapelet lengths ");
        exit(-1);
    }

    // we hold the shapelet values in a temporary vector so that we can manipulate and change this data without modifing the time series
    pivot_values = (double *) malloc(pivot_shapelet->length * sizeof(double));
    target_values = (double *) malloc(target_shapelet->length * sizeof(double));

    // load temporary value vector
    for(int i=0; i < pivot_shapelet->length; i++)
    {
        pivot_values[i] = get_value(pivot_shapelet, i);
        target_values[i] = get_value(target_shapelet, i);
    }
    
    // normalize shapelets values to make the transform scale-independent
    normalize_values(pivot_values, pivot_shapelet->length);
    normalize_values(target_values, target_shapelet->length);

    total_distance = 0.0;
    for (uint16_t i = 0; i < pivot_shapelet->length; i++)
        total_distance += pow(pivot_values[i] - target_values[i], 2);
    
    free(pivot_values);
    free(target_values);
    
    return total_distance;
}

// Distance from a shapelet to an entire time-series
double shapelet_ts_distance(Shapelet *pivot_shapelet, double *time_series, uint16_t ts_len){
    double shapelet_distance, minimum_distance = INFINITY;
    Shapelet ts_shapelet;
    uint32_t i, num_shapelets;
    
    num_shapelets = ts_len - pivot_shapelet->length + 1;                          // number of shapelets of length "shapelet_len" in time_series
    // Loops over shapelets in the time-series
    for (i=0; i<num_shapelets; i++){
        // initialize shapelet i
        ts_shapelet = init_shapelet(time_series, i, pivot_shapelet->length);
        
        // Compute shapelet-shapelet distance
        shapelet_distance = fp_euclidean_distance(pivot_shapelet, &ts_shapelet);
        
        // Keep the minimum distance between the pivot shapelet and all the time-series shapelets
        if (shapelet_distance < minimum_distance)
            minimum_distance = shapelet_distance;
    }
    
    return minimum_distance;
}


// [HARDWARE-friendly, reducing memory transfer] Distances from all the "shapelet_len"-sized shapelets in a time series to another time series (FREE RETURNED POINTER AFTER USAGE)
double *length_wise_distances(double *pivot_ts, double *target_ts, uint16_t ts_len, uint16_t shapelet_len){
    uint16_t i, num_shapelets;
    Shapelet pivot_shapelet; 
    double *shapelets_target_distances, distance;
    
    if (shapelet_len > ts_len){
        perror("Shapelet length greater than time series length");
        exit(-1);
    }
    
    num_shapelets = (ts_len - shapelet_len + 1);
    shapelets_target_distances = (double*) malloc(num_shapelets * sizeof(double));           // Array of all "shapelet_len"-sized distances to a given time series
    
    for(i = 0; i < num_shapelets; i++){
        pivot_shapelet = init_shapelet(pivot_ts, i, shapelet_len);
        distance = shapelet_ts_distance(&pivot_shapelet, target_ts, ts_len);
        shapelets_target_distances[i] = distance;
        //printf("Distance from shapelet %d of pivot TS to target TS: %.5lf \n", i, distance);
    }
    
    return shapelets_target_distances;
}


// F-Statistic based on distance measures and associated classes
double f_statistic(double *measured_distances, uint8_t *ts_classes, uint16_t num_of_ts, uint8_t num_classes){
    double f_stat;
    double total_dists_sum, total_dists_average, *class_dist_sums, *class_dist_averages;
    double final_averages_sum, final_individual_sum;
    double **distances_by_class;
    uint16_t *ts_per_class, *class_wise_counter;
    uint16_t i, j;
    uint8_t class;
    
    // Allocate memory for sums and averages
    class_dist_sums = (double*) malloc(num_classes * sizeof(double));
    class_dist_averages = (double*) malloc(num_classes * sizeof(double));
    
    // Allocate the number of members per class and class-wise counter
    ts_per_class = (uint16_t*) malloc(num_classes * sizeof(uint16_t));
    class_wise_counter = (uint16_t*) malloc(num_classes * sizeof(uint16_t));
    
    // Initialize class-dependent values
    /*
    for(i = 0; i < num_classes; i++){
        ts_per_class[i] = 0;
        class_wise_counter[i] = 0;
        class_dist_sums[i] = 0.0;
    }
    */
    if(!memset(ts_per_class, 0, num_classes * sizeof(uint16_t)))
    {
        perror("Error, could not initiliaze ts_per_class: ");
        exit(errno);
    }
    if(!memset(class_wise_counter, 0, num_classes * sizeof(uint16_t)))
    {
        perror("Error, could not initiliaze class_wise_counter: ");
        exit(errno);
    }
    if(!memset(class_dist_sums, 0, num_classes * sizeof(double)))
    {
        perror("Error, could not initiliaze class_dist_sums: ");
        exit(errno);
    }
        
    // Count number of members from each class
    for (i = 0; i < num_of_ts; i++){
        class = ts_classes[i];
        ts_per_class[class]++;
    }
    
    // Allocate the splitted distances by class
    distances_by_class = (double**) malloc(num_classes * sizeof(double*));
    for (i = 0; i < num_classes; i++)
        distances_by_class[i] = (double*) malloc(ts_per_class[i] * sizeof(double));
    
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
        class_dist_averages[i] = class_dist_sums[i]/ts_per_class[i];
    
    // Calculate final averages sum
    final_averages_sum = 0.0;
    for(i = 0; i < num_classes; i++)
        final_averages_sum += pow((class_dist_averages[i] - total_dists_average),2);
    
    // Calculate final individual sum
    final_individual_sum = 0.0;
    for(i = 0; i < num_classes; i++){
        for(j = 0; j < ts_per_class[i]; j++)
            final_individual_sum += pow((distances_by_class[i][j] - class_dist_averages[i]),2);
    }
    
    // Free allocated memory
    free(class_dist_averages);
    free(class_dist_sums);
    free(ts_per_class);
    free(class_wise_counter);
    for (i = 0; i < num_classes; i++)
        free(distances_by_class[i]);
    free(distances_by_class);
    
    // Calculate F-Statistic
    f_stat = (final_averages_sum/(num_classes - 1))/(final_individual_sum/(num_of_ts - num_classes));
    
    return f_stat;
}

// Apply quick sort in a set of shapelets, ordering by quality measure
void qsort_shapelets(Shapelet *shapelet_set, uint16_t size){
    // Compare shapelets quality measures for sorting with qsort() inside the scope
    int compare_shapelets(const void *shapelet_1, const void *shapelet_2){
        const double shapelet_1_quality = ((const Shapelet *)shapelet_1)->quality;
        const double shapelet_2_quality = ((const Shapelet *)shapelet_2)->quality;
        
        printf("Q1: %g, Q2: %g\n", shapelet_1_quality, shapelet_2_quality);
        if (shapelet_1_quality < shapelet_2_quality)
            return 1;
        else{
            if (shapelet_1_quality > shapelet_2_quality)
                return -1;
            else
                return 0;
        }
    }
    
    qsort(shapelet_set, (size_t) size, sizeof(Shapelet *), compare_shapelets);
}

// SHAPELET CACHED SELECTION (from algorithm 3 in "Classification of time series by shapelet transformation", Hills et al., 2013)
// Given a set T of time series attatched to labels, extract shapelets exhaustively from min to max lengths, keeping only the k best shapelets according to some criteria 
// (DESTROY ALL k RETURNED SHAPELETS AFTER USAGE)
Shapelet *shapelet_cached_selection(double **T, uint8_t *ts_classes, uint16_t num_of_ts, uint16_t ts_len, uint16_t min, uint16_t max, uint16_t k){
    uint16_t i, l, j, position,  current_len, shapelets_index;
    uint32_t num_shapelets, total_num_shapelets;
    Shapelet *k_shapelets, *ts_shapelets;
    Shapelet shapelet_candidate;
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
        ts_shapelets = (Shapelet *) malloc(total_num_shapelets * sizeof(Shapelet));
        shapelets_index = 0;
        // For each length between min and max
        for (l = min; l <= max; l++){ 
            num_shapelets = ts_len - l + 1;                                                                     // Number of shapelets of length l in T[i]
            // For each shapelet of the given length
            for (position = 0; position < num_shapelets; position++){
                shapelet_candidate = init_shapelet(T[i], position, l);                                            // Assemble each shapelet on the fly, instead of keeping them in a matrix
                shapelet_distances = (double*) malloc(num_of_ts * sizeof(double));
                
                // Calculate distances from current shapelet candidate to each time series in T, 
                for (j = 0; j < num_of_ts; j++)
                    shapelet_distances[j] = shapelet_ts_distance(&shapelet_candidate, T[j], ts_len);    
                
                // F-Statistic as shapelet quality measure
                shapelet_candidate.quality = f_statistic(shapelet_distances, ts_classes, num_of_ts, 2);
                free(shapelet_distances);   //shapelet_distances is only used to measure quality

                // Store every shapelet of T[i] with its quality measure and length in the format [quality, length, shapelet] with shapelet = [s1, s2, ..., sl] 
                ts_shapelets[shapelets_index] = shapelet_candidate;
                shapelets_index++;
            }         
        }  // Here all shapelets from T[i] should have been stored together with its quality measures in ts_shapelets                                                             
        
        // Sort shapelets by quality
        qsort_shapelets(ts_shapelets, total_num_shapelets);
        
        // Remove self similar shapelets
        
        
        // Merge ts_shapelets with k_shapelets and keep only best k shapelets, destroying all total_num_shapelets in ts_shapelets
        merge_shapelets(k_shapelets, k, ts_shapelets, total_num_shapelets);
        free(ts_shapelets);
        
    }
    
    return k_shapelets;
}


// Remove self similar shapelets (shapelets with overlapping indices)
// Shapelet *remove_self_similars(Shapelet *ts_shapelets, uint64_t size){
// }


// Merge ts_shapelets with k_shapelets and keep only best k shapelets
void merge_shapelets(Shapelet* k_shapelets, uint16_t k, Shapelet* ts_shapelets, uint64_t ts_num_shapelets){
    uint64_t i;
    Shapelet* all_shapelets;
    
    all_shapelets = (Shapelet *) malloc((k+ts_num_shapelets) * sizeof(Shapelet));
    for (i = 0; i < ts_num_shapelets + k; i++){
        if (i < k)
            all_shapelets[i] = k_shapelets[i];
        else
            all_shapelets[i] = ts_shapelets[i-k];
    }
    
    qsort_shapelets(all_shapelets, ts_num_shapelets + k);
    for(i = 0; i < k; i++)
        k_shapelets[i] = all_shapelets[i];
    
    free(all_shapelets);
    
}
    
    
    
    
    
    
    
    
    
    
    
    
    
    