//
// september, 2019


#include "shapelet_transform.h"
#include <time.h>

// Allocates memory and checks for allocation error
void *safe_alloc(size_t size)
{
    void * p = malloc(size);
    assert(p != NULL && size > 0);
    if(p == NULL && size > 0){
        perror("Error allocating memory!\n");
        exit(errno);
    }
    return p;
}


// Returns a timeseries structure of a given class_id 
Timeseries init_timeseries(numeric_type *values, uint8_t class, uint16_t length)
{
    Timeseries ts;
    ts.class = class;
    ts.values = values;
    ts.length = length;
    return ts;
}


// Initializes a shapelet struct with given values
Shapelet init_shapelet(Timeseries *time_series, uint16_t shapelet_position, uint16_t shapelet_len){
    Shapelet shapelet; 
    shapelet.length = shapelet_len;
    shapelet.quality = 0;
    shapelet.start_position = shapelet_position;
    shapelet.Ti = time_series;
    return shapelet;
}


// Generic vector normalization
void algebric_normalization(numeric_type *values, uint16_t length){
    numeric_type squares_sum, absolute_value;
    
    squares_sum = 0;
    #ifndef USE_FIXED                                  // Floating point normalization
    // Compute absolute value
    for (uint16_t i = 0; i < length; i++){
        squares_sum += pow(values[i], 2);
    }
    absolute_value = sqrt(squares_sum);
    //printf("Abs: %g\n", absolute_value);
    
    // check for possible division by zero error
    if(absolute_value == 0)
        return;

    // Compute normalized vector values
    //printf("Normalized value: ");
    for (uint16_t i = 0; i < length; i++){
        values[i] = values[i] / absolute_value;
        //printf("%g\t", values[i]);
    }
    
    #else                                           // Fixed point normalization
    // Compute absolute value
    for (uint16_t i = 0; i < length; i++){
        squares_sum += fixedpt_pow2(values[i]);
    }
    absolute_value = fixedpt_sqrt(squares_sum);
    //printf("Abs: %s\n", fixedpt_cstr(absolute_value, 3));
    // Check for possible future division by zero
    if(absolute_value == 0)
        return;
    
    // Compute normalized vector values
    //printf("Normalized values: ");
    for (uint16_t i = 0; i < length; i++){
        values[i] = fixedpt_div(values[i], absolute_value);    
        //printf("%s\t", fixedpt_cstr(values[i], 3));
    }
    #endif
}

// Z score vector normalization
// this is the original normalization used for shapelet discovery algorithm
// z score a.k.a. standardizing or normalizing (using sameple std_deviation)
// each element of input values vector will be changed to:
// values[i] = (values[i] - mean)/std_deviation
void zscore_normalization(numeric_type *values, uint16_t length){
    numeric_type mean, std;
    #ifndef USE_FIXED 
    #ifdef USE_EXPECTED_VALUE
    // Computation of standard deviation by population formula (based on the properties of expected values)
    numeric_type s = 0, s2 = 0;
    for (uint16_t i = 0; i < length; i++){
        s += values[i];
        s2 += pow((double) values[i], 2);
    }
    
    mean = s / length;
    std = sqrt((s2 - pow((double) mean, 2)) / length);
    // printf("Mi = %g, sigma = %g\n", mean, std);
    
    #else  
    // Computation of standard deviation by sample formula
    
    numeric_type differrence_sum;
    
    // calculate arithmetic mean 
    mean = 0;
    for(uint16_t i=0; i < length; i++){
        mean += values[i];
    }
    mean /= length;

    // calculate sum (xi - mean)^2
    differrence_sum = 0;
    for(uint16_t i=0; i < length; i++){
        differrence_sum += pow(values[i] - mean, 2);
    }
    // divide sum by N - 1 
    differrence_sum /= (length - 1); // this is sample std deviation. Remove the -1 to make it population std_dev
    // take the sqrt
    std = sqrt(differrence_sum);
    
    if (length % 32 == 0){
        // Union to represent float as unsigned without type punning
        union {
            float f;
            uint32_t u;
        } f2u_mean, f2u_std;
        f2u_mean.f = mean;
        f2u_std.f = std;
        printf("mean: %08x, std: %08x\n", f2u_mean.u, f2u_std.u);
    }

    #endif
    
    // special case, when the vector is a straight line and has no variance
    // the std results in zero, all values in the vector are set to zero
    if(std == 0){   
        memset(values, 0, length * sizeof(*values));
    }
    else{
        // calculate the z score for each element
        for(uint16_t i=0; i < length; i++){
            values[i] = (values[i] - mean) / std;
        }
    }
    
    #else
    printf("Error, z-score isn't yet  defined in fixed point representation");
    exit(-1);
    #endif
}


numeric_type euclidean_distance(numeric_type *pivot_values, numeric_type *target_values, uint16_t length, numeric_type current_minimum_distance){
    numeric_type total_distance = 0.0;
    
    #ifndef USE_FIXED
    for (uint16_t i = 0; i < length; i++){
    #ifdef USE_ABS
        //uses the absolute value of differences instead of power. Experimental.
        total_distance += fabs((double) (pivot_values[i] - target_values[i]) );
    #else
        // the default calculation
        total_distance += sqrt(pow((double)(pivot_values[i] - target_values[i]), 2.0));
    #endif
        //early abandon: in case partial distance sum result is bigger than the current minimun distance, we discard the calculation and return INFINITY
        if(total_distance >= current_minimum_distance) return INFINITY;
    }
    
    #else
    #ifdef USE_ABS
    printf("Error, euclidean distance using ABS isn't yet defined in fixed point representation");
    exit(-1);
    #else
    for(uint16_t i = 0; i < length; i++){
        //printf("values %d\n",i);       fixedpt_print(pivot_values[i]);        fixedpt_print(target_values[i]);
        total_distance += fixedpt_pow2(pivot_values[i] - target_values[i]);
        // printf("ED %d: ",i); fixedpt_print(total_distance);
        if(total_distance >= current_minimum_distance) return MAX_FIXEDPT;
    }  
    #endif 
    
    #endif
    
    return total_distance;
}


// Distance from a shapelet to an entire time-series
numeric_type shapelet_ts_distance(Shapelet *pivot_shapelet, const Timeseries *time_series){
    numeric_type shapelet_distance, minimum_distance;
    numeric_type *pivot_values, *target_values;                                              // we hold the shapelet values in a temporary vector so that we can manipulate and change this data without modifing the time series
    const uint32_t num_shapelets = time_series->length - pivot_shapelet->length + 1;         // number of shapelets of length "shapelet_len" in time_series    uint8_t print_flag;
    uint32_t closer_shapelet = 0;
    
    //printf("Time series %p\n", time_series);
    #ifndef USE_FIXED
    minimum_distance = INFINITY;
    #else
    minimum_distance = MAX_FIXEDPT;
    #endif
    
    // Normalize pivot 
    pivot_values = safe_alloc(pivot_shapelet->length * sizeof(*pivot_values));
    memcpy(pivot_values, &pivot_shapelet->Ti->values[pivot_shapelet->start_position], pivot_shapelet->length * sizeof(*pivot_values));
    
    // Test vectors extraction. Refer to readme_vectors.txt for more information.
    if (pivot_shapelet->length % 32 == 0){
        printf("%08x\n", pivot_shapelet->length);
        printf("Pivot shapelet\n");
        print_shapelet_elements(pivot_values, pivot_shapelet->length);
    }
    
    #ifdef USE_ZSCORE
    zscore_normalization(pivot_values, pivot_shapelet->length);
    #else
    algebric_normalization(pivot_values, pivot_shapelet->length);
    #endif
        
    // Test vectors extraction. Refer to readme_vectors.txt for more information.
    if (pivot_shapelet->length % 32 == 0){
        printf("%08x\n", pivot_shapelet->length);
        printf("Normalized pivot shapelet\n");
        print_shapelet_elements(pivot_values, pivot_shapelet->length);
    }

    // Allocate memory for target values 
    // Pivot shapelet and ts shapelets must always have equal length
    target_values = safe_alloc(pivot_shapelet->length * sizeof(*target_values));

    // Loops over shapelets in the time-series
    // for (uint32_t i=0; i<num_shapelets; i++){
    uint32_t i = 0;
        //printf("Target shapelet %d\n", i);
        // initialize normalized values of time series shapelet starting at i
        memcpy(target_values, &time_series->values[i], pivot_shapelet->length * sizeof(*target_values));
        
        // Test vectors extraction. Refer to readme_vectors.txt for more information.
        if (pivot_shapelet->length % 32 == 0){
            printf("Target shapelet\n");
            print_shapelet_elements(target_values, pivot_shapelet->length);
        }
        
        // Normalize target shapelet values
        #ifdef USE_ZSCORE
        zscore_normalization(target_values, pivot_shapelet->length);
        #else
        algebric_normalization(target_values, pivot_shapelet->length);
        #endif
        
        if (pivot_shapelet->length % 32 == 0){
            printf("Normalized target shapelet\n");
            print_shapelet_elements(target_values, pivot_shapelet->length);
        }

        // Compute shapelet-shapelet distance
        shapelet_distance = euclidean_distance(pivot_values, target_values, pivot_shapelet->length, minimum_distance);
        
        // Test vector extraction. Refer to readme_vectors.txt for more information.
        if (pivot_shapelet->length % 32 == 0){
            //printf("Distance\n");
            // Union to represent float as unsigned without type punning
            union {
                float f;
                uint32_t u;
            } f2u;
            f2u.f = shapelet_distance;
            printf("%08x\n", f2u.u);
        }
        
        // Keep the minimum distance between the pivot shapelet and all the time-series shapelets
        if (shapelet_distance < minimum_distance){
            minimum_distance = shapelet_distance;
            closer_shapelet = i;
        }
        
        //printf("Shapelet minimum distance: "); fixedpt_print(minimum_distance);
    // }
    //  printf("closer shapelet: (%d) (%g)\n", closer_shapelet, minimum_distance);

    free(pivot_values);
    free(target_values);

    return minimum_distance;
}



// F-Statistic based on distance measures and associated binary classes
numeric_type bin_f_statistic(numeric_type *measured_distances, Timeseries *ts_set, uint16_t num_ts){
    numeric_type f_stat;
    numeric_type total_dists_sum = 0.0, class_zero_sum = 0.0, class_one_sum = 0.0;
    numeric_type total_dists_avg, class_zero_avg, class_one_avg;
    numeric_type numerator_sum = 0.0, denominator_sum = 0.0;
    uint16_t class_zero_ts_num = 0, class_one_ts_num = 0;
    
    if(num_ts <= 2)
    {
        printf("Number of time series must be greater than 2!");
        exit(-1);
    }

    // Count the number of time series in each class and compute the sum of distaces for each class
    for(uint16_t i = 0; i < num_ts; i++){
        if (ts_set[i].class == 0){
            class_zero_sum += measured_distances[i];
            class_zero_ts_num++;
        }
        else if (ts_set[i].class == 1){
            class_one_sum += measured_distances[i];
            class_one_ts_num++;
        }
        else{
            printf("Class is not binary");
            exit(-1);
        }
    }

    #ifndef USE_FIXED
    // Calculate average values for each class and for the entire distances array
    class_zero_avg = class_zero_sum/class_zero_ts_num;
    class_one_avg = class_one_sum/class_one_ts_num;
    total_dists_sum = class_zero_sum + class_one_sum;
    total_dists_avg = total_dists_sum/num_ts;
    
    //printf("Class 0/1 sums, avgs, tota_dists_sum, total_dists_avg:\n%g\n%g\n%g\n%g\n%g\n%g\n", class_zero_sum, class_one_sum, class_zero_avg, class_one_avg, total_dists_sum, total_dists_avg);
    
    // Calculate the sum in f-stat formula numerator
    numerator_sum = pow(class_zero_avg - total_dists_avg, 2) + pow(class_one_avg - total_dists_avg, 2);
    // Calculate the sums in f-stat formula denominator
    for(uint16_t i = 0; i < num_ts; i++){
        //printf("Denominator sum before: %g\n", denominator_sum);
        if (ts_set[i].class == 0){
            denominator_sum += pow(measured_distances[i] - class_zero_avg, 2);
        }
        else if (ts_set[i].class == 1){
            denominator_sum += pow(measured_distances[i] - class_one_avg, 2);
        }
        else{
            printf("Class is not binary");
            exit(-1);
        }
        //printf("Denominator sum after: %g\n", denominator_sum);
    }
    if(denominator_sum == 0)
    {
        printf("Error calculating f statistic! Division by zero\n");
        exit(-1);
    }
    f_stat = numerator_sum / (denominator_sum/(num_ts-2));
    #else
    // Calculate average values for each class and for the entire distances array
    class_zero_avg = fixedpt_div(class_zero_sum, fixedpt_fromint(class_zero_ts_num));
    class_one_avg = fixedpt_div(class_one_sum, fixedpt_fromint(class_one_ts_num));
    total_dists_sum = class_zero_sum + class_one_sum;
    total_dists_avg = fixedpt_div(total_dists_sum, fixedpt_fromint(num_ts));
    //printf("Class 0/1 sums, avgs, tota_dists_sum, total_dists_avg:\n");   fixedpt_print(class_zero_sum); fixedpt_print(class_one_sum); fixedpt_print(class_zero_avg);  fixedpt_print(class_one_avg);   fixedpt_print(total_dists_sum); fixedpt_print(total_dists_avg);
    // Calculate the sum in f-stat formula numerator
    numerator_sum = fixedpt_pow2(class_zero_avg - total_dists_avg) + fixedpt_pow2(class_one_avg - total_dists_avg);
    // Calculate the sums in f-stat formula denominator
    for(uint16_t i = 0; i < num_ts; i++){
        //printf("Denominator sum before: ");        fixedpt_print(denominator_sum);
        if(ts_set[i].class == 0){
            temp_difference = measured_distances[i] - class_zero_avg;
        }
        else if (ts_set[i].class == 1){
            temp_difference = measured_distances[i] - class_one_avg;
        }
        else{
            printf("Class is not binary");
            exit(-1);
        }
        //printf("temp dif: ");   fixedpt_print(temp_difference);
        //printf("temp dif squared: "); fixedpt_print(fixedpt_pow2(temp_difference));
        denominator_sum += fixedpt_pow2(temp_difference);
        
    }
    if(denominator_sum == 0)
    {
        printf("Error calculating f statistic! Division by zero\n");
        exit(-1);
    }
    
    f_stat = fixedpt_div(numerator_sum, fixedpt_div(denominator_sum, (fixedpt_fromint(num_ts) - FIXEDPT_TWO)));
    
    #endif
    
    return f_stat;
}

// floating point F-Statistic based on distance measures and associated classes
/*
float f_statistic(float *measured_distances, uint8_t *ts_classes, uint16_t num_ts, uint8_t num_classes){
    float f_stat;
    float total_dists_sum, total_dists_average, *class_dist_sums, *class_dist_averages;
    float final_averages_sum, final_individual_sum;
    float **distances_by_class;
    uint16_t *ts_per_class, *class_wise_counter;
    uint16_t i, j;
    uint8_t class;
    
    // Allocate memory for sums and averages
    class_dist_sums =  safe_alloc(num_classes * sizeof(*class_dist_sums));
    class_dist_averages =  safe_alloc(num_classes * sizeof(*class_dist_averages));
    
    // Allocate the number of members per class and class-wise counter
    ts_per_class = safe_alloc(num_classes * sizeof(uint16_t));
    class_wise_counter = safe_alloc(num_classes * sizeof(uint16_t));
    
    // Initialize class-dependent values
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
    if(!memset(class_dist_sums, 0, num_classes * sizeof(*class_dist_sums)))
    {
        perror("Error, could not initiliaze class_dist_sums: ");
        exit(errno);
    }
        
    // Count number of members from each class
    for (i = 0; i < num_ts; i++){
        class = ts_classes[i];
        ts_per_class[class]++;
    }
    
    // Allocate the splitted distances by class
    distances_by_class = safe_alloc(num_classes * sizeof(*distances_by_class));
    for (i = 0; i < num_classes; i++)
        distances_by_class[i] = safe_alloc(ts_per_class[i] * sizeof(**distances_by_class));
    
    total_dists_sum = 0.0;
    // Split distances by class and calculate sums
    for(i = 0; i < num_ts; i++){
        class = ts_classes[i];
        distances_by_class[class][class_wise_counter[class]] = measured_distances[i];
        class_wise_counter[class]++;
        
        // Total and class-wise sums
        class_dist_sums[class] += measured_distances[i];
        total_dists_sum += measured_distances[i];
    }
    
    // Calculate total and class-wise averages
    total_dists_average = total_dists_sum/num_ts;
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
    f_stat = (final_averages_sum/(num_classes - 1))/(final_individual_sum/(num_ts - num_classes));
    
    return f_stat;
}
*/

// Compare shapelets quality measures for sorting with qsort()
static int compare_shapelets(const void *shapelet_1, const void *shapelet_2){
    const numeric_type shapelet_1_quality = ((const Shapelet *)shapelet_1)->quality;
    const numeric_type shapelet_2_quality = ((const Shapelet *)shapelet_2)->quality;
    
    if (shapelet_1_quality < shapelet_2_quality)
    {
        return 1;
    }
    else if (shapelet_1_quality > shapelet_2_quality)
    {
        return -1;
    }
    else
    {
        return 0;
    }
}


// SHAPELET CACHED SELECTION (from algorithm 3 in "Classification of time series by shapelet transformation", Hills et al., 2013)
// Given a set T of time series attatched to labels, extract shapelets exhaustively from min to max lengths, keeping only the k best shapelets according to some criteria 
// (DESTROY ALL k RETURNED SHAPELETS AFTER USAGE)
Shapelet *shapelet_cached_selection(Timeseries * T, uint16_t num_ts, uint16_t min, uint16_t max, uint16_t k){
    uint16_t i, l, j, position, shapelets_index;
    uint32_t num_shapelets; //number of shapelets of lenght l 
    uint32_t total_num_shapelets; //total number of shapelets of a given timeseries length from given min and max shapelet lenght parameters
    uint32_t num_merged_shapelets; //total number of shapelets to be merged after removing self similars
    Shapelet *k_shapelets, *ts_shapelets;
    Shapelet shapelet_candidate;
    numeric_type *shapelet_distances;
    
    //checks to assert if the parameters are valid
    if (min > max){
        printf("Min greater than max");
        exit(-1);
    }

    if(num_ts <= 2)
    {
        printf("Number of time series must be greater than 2");
        exit(-1);
    }

    k_shapelets = safe_alloc(k*sizeof(*k_shapelets));
    if(memset(k_shapelets, 0, k * sizeof(*k_shapelets)) == NULL)
    {
        printf("Error on memset k_shapelets\n");
        exit(-1);
    }

    // total number of shapelets in each T[i] 
    total_num_shapelets = (min-max-1) * (max + min - 2*T->length - 2)/(2);
    // printf("Total number of shapelets for each time-series: %u\n", total_num_shapelets);
    
    // For each time-series T[i] in T
    // for (i = 0; i < num_ts; i++){
    i = 0;
        ts_shapelets = safe_alloc(total_num_shapelets * sizeof(*ts_shapelets));
        shapelets_index = 0;
        // printf("[TS %u]\n", i);
        //printf("Shapelet #\tquality\n");
        // For each length between min and max
        for (l = min; l <= max; l++){ 
            num_shapelets = T->length - l + 1;    
            // For each shapelet of the given length
            // for (position = 0; position < num_shapelets; position++){
            position = 0;
                shapelet_candidate = init_shapelet(&T[i], position, l);                                         // Assemble each shapelet on the fly, instead of keeping them in a matrix
                shapelet_distances = safe_alloc(num_ts * sizeof(*shapelet_distances));
                //printf("(Pivot shapelet %d)\n", shapelets_index);
                // Calculate distances from current shapelet candidate to each time series in T, 
                // for (j = 0; j < num_ts; j++){
                for (j = 0; j < 5; j++){
                    //printf("target TS %d\n", j);
                    shapelet_distances[j] = shapelet_ts_distance(&shapelet_candidate, &T[j]);   
                }

                // F-Statistic as shapelet quality measure
                shapelet_candidate.quality = bin_f_statistic(shapelet_distances, T, num_ts);
                
                //printf("%u\t\t%g\n", shapelets_index, shapelet_candidate.quality);
                free(shapelet_distances);   //shapelet_distances is only used to measure quality
                // Store every shapelet of T[i] with its quality measure and length in the format [quality, length, shapelet] with shapelet = [s1, s2, ..., sl] 
                ts_shapelets[shapelets_index] = shapelet_candidate;
                shapelets_index++;
            // }         
        }  // Here all shapelets from T[i] should have been stored together with its quality measures in ts_shapelets                                                             
        
        // Sort shapelets by quality
        qsort(ts_shapelets, (size_t) total_num_shapelets, sizeof(*ts_shapelets), compare_shapelets);
        // Remove self similar shapelets
        num_merged_shapelets = total_num_shapelets;
        ts_shapelets = remove_self_similars(ts_shapelets, &num_merged_shapelets);
        // Merge ts_shapelets with k_shapelets and keep only best k shapelets, destroying all total_num_shapelets in ts_shapelets
        merge_shapelets(k_shapelets, k, ts_shapelets, num_merged_shapelets);
        //printf("After merging\n");
        //print_shapelets_ids(k_shapelets, k, T);
        free(ts_shapelets);
    // }
    
    return k_shapelets;
}

//thread specific global variables and structures:
typedef struct{
    Shapelet * ts_shapelets;
    uint16_t *shapelets_index;
    uint16_t num_ts;
    Timeseries * T; //pointer to  timeseries array
    uint16_t i;     // current timeseries index
    pthread_mutex_t * mutex;
    uint16_t max;
    uint16_t min;
} Thread_args;  // thread containing the argument for each thread function


static void *task_shapelet_candidates(void * arg)
{
    uint32_t num_shapelets; //number of shapelets of lenght l 
    Shapelet shapelet_candidate;
    numeric_type *shapelet_distances;
    // arguments passed via structure
    Shapelet * ts_shapelets = ((Thread_args *) arg)->ts_shapelets;
    uint16_t *shapelets_index = ((Thread_args *) arg)->shapelets_index;
    uint16_t num_ts = ((Thread_args *) arg)->num_ts;
    Timeseries *T = ((Thread_args *) arg)->T;
    uint16_t i = ((Thread_args *) arg)->i;
    pthread_mutex_t * mutex = ((Thread_args *) arg)->mutex;
    uint16_t max = ((Thread_args *) arg)->max;
    uint16_t min = ((Thread_args *) arg)->min;

    // For each length between min and max
    for (int l = min; l <= max; l++){ 
        num_shapelets = T->length - l + 1;    

        // For each shapelet of the given length
        for (int position = 0; position < num_shapelets; position++){
            shapelet_candidate = init_shapelet(&T[i], position, l);  // Assemble each shapelet on the fly, instead of keeping them in a matrix
            shapelet_distances = safe_alloc(num_ts * sizeof(*shapelet_distances));
            
            // Calculate distances from current shapelet candidate to each time series in T, 
            for (int j = 0; j < num_ts; j++)
                shapelet_distances[j] = shapelet_ts_distance(&shapelet_candidate, &T[j]);   

            // F-Statistic as shapelet quality measure
            shapelet_candidate.quality = bin_f_statistic(shapelet_distances, T, num_ts);
            
            free(shapelet_distances);   //shapelet_distances is only used to measure quality
            // Store every shapelet of T[i] with its quality measure and length in the format [quality, length, shapelet] with shapelet = [s1, s2, ..., sl] 
            pthread_mutex_lock(mutex);
                ts_shapelets[*shapelets_index] = shapelet_candidate;    //ts_shapelts and index are shared between threads
                *shapelets_index = *shapelets_index + 1;
            pthread_mutex_unlock(mutex);
        }
    }    

    pthread_exit(NULL);    
}


//implements shapelet_cached_selection using multiple threads
Shapelet *multi_thread_shapelet_cached_selection(Timeseries * T, uint16_t num_ts, const uint16_t min, const uint16_t max, uint16_t k, const uint16_t max_num_threads){
    uint16_t i, shapelets_index;
    uint32_t total_num_shapelets; //total number of shapelets of a given timeseries length from given min and max shapelet lenght parameters
    uint32_t num_merged_shapelets; //total number of shapelets to be merged after removing self similars
    Shapelet *k_shapelets, *ts_shapelets;

    // thread spefic variables:
    pthread_t * threads;
    Thread_args * args;    // argument vector for each thread used
    pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER; // mutex to controll shared resources (shapelet_index)
    uint16_t num_threads;       // actual number of threads used
    uint16_t lengths_per_thread;
    //checks to assert if the parameters are valid
    if (min > max){
        printf("Min greater than max");
        exit(-1);
    }

    if(max_num_threads <= 0)
    {
        printf("Maximun number of threads must be greater than zero!\n");
    }

    if(num_ts <= 2)
    {
        printf("Number of time series must be greater than 2!");
        exit(-1);
    }

    k_shapelets = safe_alloc(k*sizeof(*k_shapelets));
    if(memset(k_shapelets, 0, k * sizeof(*k_shapelets)) == NULL)
    {
        printf("Error on memset k_shapelets\n");
        exit(-1);
    }

    // total number of threads created depends on max and min input
    if(max - min <= max_num_threads){
        num_threads = max - min + 1;        // we can use up to max - min + 1 threads in this application
    }
    else{
        num_threads = max_num_threads;
    }
    //alocate threads and arguments
    threads = safe_alloc(num_threads * sizeof(*threads));
    args = safe_alloc(num_threads * sizeof(*args));

    // total number of shapelets in each T[i] 
    total_num_shapelets = (min-max-1) * (max + min - 2*T->length - 2)/(2);
    printf("Total number of shapelets for each time-series: %u\n", total_num_shapelets);

    lengths_per_thread = (max - min + 1) / num_threads;  // number of lengths each thread will calculated

    // For each time-series T[i] in T
    for (i = 0; i < num_ts; i++){
        ts_shapelets = safe_alloc(total_num_shapelets * sizeof(*ts_shapelets));
        shapelets_index = 0;
        //printf("[TS %u]\n", i);

        // For each length between min and max
        for (int tid = 0; tid < num_threads; tid++){
            //set arguments for each running thread
            args[tid].ts_shapelets = ts_shapelets;
            args[tid].shapelets_index = &shapelets_index;
            args[tid].num_ts = num_ts;
            args[tid].T = T;
            args[tid].i = i;
            args[tid].mutex = &mutex;
            // alocates a load to each thread, based on min and max length that the thread will compute
            args[tid].min = min + tid*(lengths_per_thread);
            if(tid == num_threads -1 ){
                args[tid].max = max;        // last thread calculates all remaining lengths
            }
            else{
                args[tid].max = args[tid].min + lengths_per_thread - 1;     //else calculate lenghts_per_thread lengths
            }

            if( pthread_create(&threads[tid], NULL, task_shapelet_candidates, (void *) &args[tid]) ){
                perror("Error creating thread\n");
                exit(errno);
            }
        }  // Here all shapelets from T[i] should have been stored along with its quality measures in ts_shapelets                                                             
        
        //join all executing threads
        for(int tid = 0; tid < num_threads; tid++){
            if( pthread_join(threads[tid], NULL) ){
                perror("Error joining threads!\n");
                exit(errno);
            }
        }
            
        // Sort shapelets by quality
        qsort(ts_shapelets, (size_t) total_num_shapelets, sizeof(*ts_shapelets), compare_shapelets);
        // Remove self similar shapelets
        num_merged_shapelets = total_num_shapelets;
        ts_shapelets = remove_self_similars(ts_shapelets, &num_merged_shapelets);
        // Merge ts_shapelets with k_shapelets and keep only best k shapelets, destroying all total_num_shapelets in ts_shapelets
        merge_shapelets(k_shapelets, k, ts_shapelets, num_merged_shapelets);
        //print_shapelets_ids(k_shapelets, k, T);
        free(ts_shapelets);
    }

    free(threads);
    free(args);
    return k_shapelets;
}


// Returns 1 if compared shapelets are self similar, 0 otherwise
static inline int is_self_similar(const Shapelet s1, const Shapelet s2)
{
    // Shapelets must be from the same time series to be self similar
    if(s1.Ti != s2.Ti)
    {
        return 0;
    }
    // Shapelets are self similar if their indices overlap
    if( ( (s1.start_position >= s2.start_position) && (s1.start_position < s2.start_position + s2.length) ) ||
        ( (s2.start_position >= s1.start_position) && (s2.start_position < s1.start_position + s1.length) ) ) 
    {
        return 1;
    }
    else
    {
        return 0;
    }
}


// Remove self similar shapelets (shapelets with overlapping indices), return pointer to new array and update num_shapelets
Shapelet *remove_self_similars(Shapelet *ts_shapelets, uint32_t *num_shapelets){
    int self_similar, num_removed_shapelets=0;
    int ts_shapelets_size = *num_shapelets; //num_shapelets is updated later
    Shapelet *new_list;     // list cointaining only non-self similar shapelets 

    //first, we find the inidices that will be removed and set their Ti to null
    for(int i=1; i < ts_shapelets_size; i++)
    {
        self_similar = 0;
        for(int j=0; j < i; j++) 
        {
            if(is_self_similar(ts_shapelets[i], ts_shapelets[j]))
            {
                self_similar = 1;
                break;
            }
        }
        if(self_similar)
        {
            num_removed_shapelets++;
            ts_shapelets[i].Ti = NULL;
        }
    }

    //create new ts_shapelets list
    new_list = safe_alloc((ts_shapelets_size - num_removed_shapelets) * sizeof(Shapelet));

    for(int i=0, j=0; i < ts_shapelets_size; i++)
    {
        if(ts_shapelets[i].Ti != NULL) 
        {
            new_list[j] = ts_shapelets[i];
            j++;
        }
    }

    // updates the shapelet size
    *num_shapelets = ts_shapelets_size - num_removed_shapelets;
    //frees old list and points it to new one
    free(ts_shapelets);

    return new_list;
}


// Merge ts_shapelets with k_shapelets and keep only best k shapelets
void merge_shapelets(Shapelet* k_shapelets, uint16_t k, Shapelet* ts_shapelets, uint64_t ts_num_shapelets){
    Shapelet* all_shapelets;
            
    all_shapelets = safe_alloc((k+ts_num_shapelets) * sizeof(Shapelet));
    
    // Append k_shapelets and ts_shapelets into a single vector
    memcpy(all_shapelets, k_shapelets, k * sizeof(Shapelet));
    memcpy(all_shapelets + k, ts_shapelets, ts_num_shapelets * sizeof(Shapelet));
        
    // Sort merged vector by quality
    qsort(all_shapelets, ts_num_shapelets + k, sizeof(*all_shapelets), compare_shapelets);
    
    // Select only the k best shapelets from sorted vector
    memcpy(k_shapelets, all_shapelets, k * sizeof(Shapelet));

    free(all_shapelets);
}


// Get value of a shapelet at a specific position 
static inline numeric_type get_value(Shapelet *s, uint16_t j){
    return s->Ti->values[s->start_position + j];
}


// Transform set of time-series based on the distances to a set o shapelets (the Transform of the ST)
numeric_type **transform_dataset(Timeseries *T, uint16_t num_ts, Shapelet *shapelet_set, uint16_t num_shapelets){
    numeric_type **transformed_data;
    
    transformed_data = safe_alloc(num_ts * sizeof(*transformed_data));
    for (uint16_t i = 0; i < num_ts; i++){
        transformed_data[i] = safe_alloc(num_shapelets * sizeof(**transformed_data));
    }
    
    for (uint16_t i = 0; i < num_ts; i++){
        for (uint16_t j = 0; j < num_shapelets; j++){
            transformed_data[i][j] = shapelet_ts_distance(&shapelet_set[j], &T[i]);
            // printf("%g  ", transformed_data[i][j]);
        }
        // printf("\n");
    }
    
    return transformed_data;
}


// Print all positions of a certain shapelet as HEX
void print_shapelet_elements(const numeric_type * shapelet_values, uint16_t shapelet_len){
    // Union to represent float as unsigned without type punning
    union {
            float f;
            uint32_t u;
    } f2u;
    
    for (uint16_t i = 0; i < shapelet_len; i++){
        f2u.f = shapelet_values[i];
        printf("%08x ", f2u.u);
    }    
    printf("\n");
}

// Print all shapelets in a shapelet array
void print_shapelets_ids(Shapelet * S, uint16_t num_shapelets, Timeseries *T){
    uint64_t ts_i;                      // index of a given time series

    for(int i=0; i < num_shapelets; i++)
    {   
        #ifndef USE_FIXED 
        ts_i = (uint64_t)(S[i].Ti - T);
        printf("%dth Shapelet is from TS %I64d,\thas length: %d,\tstarting position: %d,\tquality: %g\n", i, ts_i, S[i].length, S[i].start_position ,S[i].quality); 
        /*for(int j = 0; j < S[i].length; j++)
            printf("%g ", get_value(&S[i], j));
        printf("\n\n");*/
        
        #else
        printf("%dth Shapelet has length: %d, quality:", i, S[i].length);
        fixedpt_print(S[i].quality);
        printf("\nValues from timseries %p:\t", S[i].Ti); 
        // for(int j = 0; j < S[i].length; j++)
            // printf("%s ", fixedpt_cstr(get_value(&S[i], j),3));
        // printf("\n\n");
            
        #endif
    }
}


// Given a set of shapelets and the base address of the time-series set they were extracted,
// write both shapelet description and values to a csv file 
// Floating-point only
void shapelets_to_files(Shapelet *shapelet_set, uint16_t num_shapelets, Timeseries *T, const char * base_filename){
    uint64_t ts_i;
    FILE *data_file_descriptor;
    FILE *info_file_descriptor;
    char data_filename[50];
    char info_filename[50];
    
    // Get data and info filenames from the basic one passed as argument
    strcpy(data_filename, base_filename);
    strcat(data_filename, "_data.csv");
    strcpy(info_filename, base_filename);
    strcat(info_filename, "_info.txt");
    
    // Open file streams for both data and info
    data_file_descriptor = fopen(data_filename, "w");
    if (data_file_descriptor == NULL){
        perror("Error, cannot open data csv file descriptor");
        exit(errno);
    }
    info_file_descriptor = fopen(info_filename, "w");
    if (info_file_descriptor == NULL){
        perror("Error, cannot open info txt file descriptor");
        exit(errno);
    }
    
    // Fulfill files with the shapelet set and its info
    for (int i = 0; i < num_shapelets; i++){
        ts_i = (uint64_t)(shapelet_set[i].Ti - T);
        // Write shapelet description
        fprintf(info_file_descriptor, "Shapelet %d is from TS %I64d,\thas length: %d,\tstarting position: %d,\tquality: %g\n", i, ts_i, shapelet_set[i].length, shapelet_set[i].start_position ,shapelet_set[i].quality);
        // Write shapelet elements
        for(int j = 0; j < shapelet_set[i].length; j++){
            fprintf(data_file_descriptor, "%g", get_value(&shapelet_set[i], j));
            // Unless its the last element, write comma
            if (j != shapelet_set[i].length - 1){
                fprintf(data_file_descriptor, ",");
            }
        }
        fprintf(data_file_descriptor, "\n");
    }
    
    fclose(data_file_descriptor);
    fclose(info_file_descriptor);
}

// Read datasets into ts_array, loading number of time-series and time-series length from file header
// Free all float arrays from ts_array and the ts_array itself 
uint16_t read_train_dataset(char * filename, Timeseries **ts_array){
    //char filename[] = "data/Wafer/Wafer_TRAIN.csv";
    FILE *file_descriptor;
    char *field;
    uint16_t num_ts, ts_len;
    const uint16_t HEADER_BSIZE = 20;
    char header_buffer[HEADER_BSIZE];
    uint16_t TS_BSIZE;
    char *time_series_buffer;
    uint8_t ts_class;
    numeric_type *ts_values;
    
    // Reads csv file and keeps its address at file_descriptor
    file_descriptor = fopen(filename, "r");
    if (file_descriptor == NULL){
        perror("Error opening csv: ");
        exit(errno);
    }
    
    // Read header containing number of time-series and time-series length
    if(!fgets(header_buffer, HEADER_BSIZE, file_descriptor)){
        perror("Error reading dataset header: ");
        exit(errno);
    }
    num_ts = (uint16_t) atoi(strtok(header_buffer, " "));
    ts_len = (uint16_t) atoi(strtok(NULL, " "));
    
    // Allocate memory for time-series buffer using estimative of characters per time-series value
    TS_BSIZE = 15 * ts_len;
    time_series_buffer = safe_alloc(TS_BSIZE * sizeof(char));
        
    // Allocate memory for the time-series array that will hold the dataset
    *ts_array = safe_alloc(num_ts * sizeof(Timeseries));
    
    // Read all num_ts time-series from the dataset
    for(uint16_t i = 0; i < num_ts; i++){
        // Load TS_BSIZE chars from file to buffer
        if(!fgets(time_series_buffer, TS_BSIZE, file_descriptor)){
            perror("Error reading time series buffer: ");
            exit(errno);
        }
        
        // If TS_BSIZE is enought to read a line of the dataset, the '\n' will be found in time_series_buffer, else exit
        if (!strchr(time_series_buffer, '\n')) {
            printf("\nTS_BSIZE is not larger than number of characters in a line\n");
            exit(-1);
        }
        
        // Allocate memory for each time-series in the dataset
        ts_values = (numeric_type *) malloc (ts_len * sizeof(*ts_values));
        
        // The first ts_len values are from the time-series, and the last one is the time-series class
        field = strtok(time_series_buffer, ",");
        //printf("TIME-SERIES %u\n %s\t",i, field);
        
        #ifndef USE_FIXED
        ts_values[0] = atof(field);
        
        for(uint16_t j = 1; j < ts_len; j++){
            field = strtok(NULL, ",");
            //printf("%s\t", field);
            ts_values[j] = atof(field);
        }
        
        #else
        ts_values[0] = fixedpt_fromfloat(atof(field));
        for(uint16_t j = 1; j < ts_len; j++){
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
        // Treats classes -1 and 2 (-1 in Wafer dataset, 2 in all the others) as 0
        ts_class = (uint8_t) (atoi(field) == 1);
        
        (*ts_array)[i] = init_timeseries(ts_values, ts_class, ts_len);
    }
    
    return num_ts;
}
