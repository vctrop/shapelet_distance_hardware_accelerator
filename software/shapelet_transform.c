//
// september, 2019

#include "shapelet_transform.h"


// Floating-point size displaying
// static void fp_sizes(void){
    // printf("Float has %ld bytes in this system\n", sizeof(float));
    // printf("Double has %ld bytes in this system\n", sizeof(double));
// }


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
Shapelet init_shapelet(numeric_type *time_series, uint16_t shapelet_position, uint16_t shapelet_len){
    Shapelet shapelet; 
    shapelet.length = shapelet_len;
    shapelet.quality = 0;
    shapelet.start_position = shapelet_position;
    shapelet.Ti = time_series;
    return shapelet;
}


// Generic vector normalization
void vector_normalization(numeric_type *values, uint16_t length){
    numeric_type squares_sum, absolute_value;
    
    squares_sum = 0;
    #if USE_FLOAT == 1                                  // Floating point normalization
    // Compute absolute value
    for (uint16_t i = 0; i < length; i++)
        squares_sum += pow(values[i], 2);
    absolute_value = sqrt(squares_sum);

    // check for possible division by zero error
    if(absolute_value == 0)
        return;

    // Compute normalized vector values
    for (uint16_t i = 0; i < length; i++)
        values[i] = values[i] / absolute_value;
    
    #else                                           // Fixed point normalization
    // Compute absolute value
    for (uint16_t i = 0; i < length; i++)
        squares_sum += fixedpt_pow(values[i], fixedpt_fromint(2)); 
    absolute_value = fixedpt_sqrt(squares_sum);
    
    // Check for possible future division by zero
    if(absolute_value == 0)
        return;
    
    // Compute normalized vector values
    for (uint16_t i = 0; i < length; i++)
        values[i] = fixedpt_div(values[i], absolute_value);    

    #endif
}


numeric_type euclidean_distance(numeric_type *pivot_values, numeric_type *target_values, uint16_t length, numeric_type current_minimum_distance){
    numeric_type total_distance = 0.0;
    
    #if USE_FLOAT == 1
    for (uint16_t i = 0; i < length; i++){
        total_distance += pow(pivot_values[i] - target_values[i], 2);
        //early abandon: in case partial distance sum result is bigger than the current minimun distance, we discard the calculation and return INFINITY
        if(total_distance >= current_minimum_distance) return INFINITY;
    }
    
    #else
    for(uint16_t i = 0; i < length; i++){
        total_distance += fixedpt_pow(pivot_values[i] - target_values[i], FIXEDPT_TWO);
        if(total_distance >= current_minimum_distance) return MAX_INT;
    }  
    #endif
    
    return total_distance;
}


// Distance from a shapelet to an entire time-series
numeric_type shapelet_ts_distance(Shapelet *pivot_shapelet, const Timeseries *time_series){
    numeric_type shapelet_distance, minimum_distance;
    numeric_type *pivot_values, *target_values;   // we hold the shapelet values in a temporary vector so that we can manipulate and change this data without modifing the time series
    uint32_t i;
    const uint32_t num_shapelets = time_series->length - pivot_shapelet->length + 1;   // number of shapelets of length "shapelet_len" in time_series
    
    #if USE_FLOAT == 1
    minimum_distance = INFINITY;
    #else
    minimum_distance = MAX_INT;
    #endif
    
    // Normalize pivot shapelet
    pivot_values = safe_alloc(pivot_shapelet->length * sizeof(*pivot_values));
    memcpy(pivot_values, &pivot_shapelet->Ti[pivot_shapelet->start_position], pivot_shapelet->length * sizeof(*pivot_values));
    
    vector_normalization(pivot_values, pivot_shapelet->length);
    
    // Allocate memory for target values 
    // Pivot shapelet and ts shapelets must always have equal length
    target_values = safe_alloc(pivot_shapelet->length * sizeof(*target_values));

    // Loops over shapelets in the time-series
    for (i=0; i<num_shapelets; i++){
        // initialize normalized values of time series shapelet starting at i
        memcpy(target_values, &time_series->values[i], pivot_shapelet->length * sizeof(*target_values));
        // Normalize target shapelet values
        vector_normalization(target_values, pivot_shapelet->length);
        
        // Compute shapelet-shapelet distance
        shapelet_distance = euclidean_distance(pivot_values, target_values, pivot_shapelet->length, minimum_distance);
        
        // Keep the minimum distance between the pivot shapelet and all the time-series shapelets
        if (shapelet_distance < minimum_distance)
            minimum_distance = shapelet_distance;
   
    }

    free(pivot_values);
    free(target_values);

    return minimum_distance;
}


// [HARDWARE-friendly, reducing memory transfer] Floating-point distances from all the "shapelet_len"-sized shapelets in a time series to another time series (FREE RETURNED POINTER AFTER USAGE)
numeric_type *length_wise_distances(numeric_type *pivot_ts, Timeseries *target_ts, uint16_t shapelet_len){
    uint16_t i, num_shapelets;
    Shapelet pivot_shapelet; 
    numeric_type *shapelets_target_distances, distance;
    
    if (shapelet_len > target_ts->length){
        perror("Shapelet length greater than time series length");
        exit(-1);
    }
    
    num_shapelets = (target_ts->length - shapelet_len + 1);
    shapelets_target_distances = safe_alloc(num_shapelets * sizeof(shapelets_target_distances));   // Array of all "shapelet_len"-sized distances to a given time series

    for(i = 0; i < num_shapelets; i++){
        pivot_shapelet = init_shapelet(pivot_ts, i, shapelet_len);
        distance = shapelet_ts_distance(&pivot_shapelet, target_ts);
        shapelets_target_distances[i] = distance;
    }
    
    return shapelets_target_distances;
}


// F-Statistic based on distance measures and associated binary classes
numeric_type bin_f_statistic(numeric_type *measured_distances, Timeseries *ts_set, uint16_t num_of_ts){
    numeric_type f_stat;
    numeric_type total_dists_sum = 0.0, class_zero_sum = 0.0, class_one_sum = 0.0;
    numeric_type total_dists_avg, class_zero_avg, class_one_avg;
    numeric_type numerator_sum = 0.0, denominator_sum = 0.0;
    uint16_t class_zero_ts_num = 0, class_one_ts_num = 0;
    
    if(num_of_ts <= 2)
    {
        printf("Number of time series must be greater than 2!");
        exit(-1);
    }

    // Count the number of time series in each class and compute the sum of distaces for each class
    for(uint16_t i = 0; i < num_of_ts; i++){
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

    #if USE_FLOAT == 1
    // Calculate average values for each class and for the entire distances array
    class_zero_avg = class_zero_sum/class_zero_ts_num;
    class_one_avg = class_one_sum/class_one_ts_num;
    total_dists_sum = class_zero_sum + class_one_sum;
    total_dists_avg = total_dists_sum/num_of_ts;
    // Calculate the sum in f-stat formula numerator
    numerator_sum = pow(class_zero_avg - total_dists_avg, 2) + pow(class_one_avg - total_dists_avg, 2);
    
    // Calculate the sums in f-stat formula denominator
    for(uint16_t i = 0; i < num_of_ts; i++){
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
    }
    if(denominator_sum == 0)
    {
        printf("Error calculating f statistic! Division by zero\n");
        exit(-1);
    }
    f_stat = numerator_sum / (denominator_sum/(num_of_ts-2));
    
    #else
    // Calculate average values for each class and for the entire distances array
    class_zero_avg = fixedpt_div(class_zero_sum, class_zero_ts_num);
    class_one_avg = fixedpt_div(class_one_sum, class_one_ts_num);
    total_dists_sum = class_zero_sum + class_one_sum;
    total_dists_avg = fixedpt_div(total_dists_sum, num_of_ts);
    // Calculate the sum in f-stat formula numerator
    numerator_sum = fixedpt_pow(class_zero_avg - total_dists_avg, FIXEDPT_TWO) + fixedpt_pow(class_one_avg - total_dists_avg, FIXEDPT_TWO);
    
    // Calculate the sums in f-stat formula denominator
    for(uint16_t i = 0; i < num_of_ts; i++){
        if(ts_set[i].class == 0){
            denominator_sum += fixedpt_pow(measured_distances[i] - class_zero_avg, FIXEDPT_TWO);
        }
        else if (ts_set[i].class == 1){
            denominator_sum += fixedpt_pow(measured_distances[i] - class_one_avg, FIXEDPT_TWO);
        }
        else{
            printf("Class is not binary");
            exit(-1);
        }
    }
    if(denominator_sum == 0)
    {
        printf("Error calculating f statistic! Division by zero\n");
        exit(-1);
    }
    
    f_stat = fixedpt_div(numerator_sum, fixedpt_div(denominator_sum, (num_of_ts - FIXEDPT_TWO)));
    #endif
    
    return f_stat;
}

// floating point F-Statistic based on distance measures and associated classes
double f_statistic(double *measured_distances, uint8_t *ts_classes, uint16_t num_of_ts, uint8_t num_classes){
    double f_stat;
    double total_dists_sum, total_dists_average, *class_dist_sums, *class_dist_averages;
    double final_averages_sum, final_individual_sum;
    double **distances_by_class;
    uint16_t *ts_per_class, *class_wise_counter;
    uint16_t i, j;
    uint8_t class;
    
    // Allocate memory for sums and averages
    class_dist_sums =  safe_alloc(num_classes * sizeof(double));
    class_dist_averages =  safe_alloc(num_classes * sizeof(double));
    
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
    distances_by_class = safe_alloc(num_classes * sizeof(double*));
    for (i = 0; i < num_classes; i++)
        distances_by_class[i] = safe_alloc(ts_per_class[i] * sizeof(double));
    
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
Shapelet *shapelet_cached_selection(Timeseries * T, uint16_t num_of_ts, uint16_t min, uint16_t max, uint16_t k){
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

    if(num_of_ts <= 2)
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

    // total number of shapelets in each T[i] 
    total_num_shapelets = (min-max-1) * (max + min - 2*T->length - 2)/(2);
    printf("Total number of shapelets for each time-series: %u\n", total_num_shapelets);
    
    // For each time-series T[i] in T
    for (i = 0; i < num_of_ts; i++){
        ts_shapelets = safe_alloc(total_num_shapelets * sizeof(*ts_shapelets));
        shapelets_index = 0;
        printf("[TS %u]\n", i);
        //printf("Shapelet #\tquality\n");
        // For each length between min and max
        for (l = min; l <= max; l++){ 
            num_shapelets = T->length - l + 1;    
            // For each shapelet of the given length
            for (position = 0; position < num_shapelets; position++){
                
                shapelet_candidate = init_shapelet(T[i].values, position, l);                                      // Assemble each shapelet on the fly, instead of keeping them in a matrix
                shapelet_distances = safe_alloc(num_of_ts * sizeof(*shapelet_distances));

                // Calculate distances from current shapelet candidate to each time series in T, 
                for (j = 0; j < num_of_ts; j++)
                    shapelet_distances[j] = shapelet_ts_distance(&shapelet_candidate, &T[j]);   

                // F-Statistic as shapelet quality measure
                shapelet_candidate.quality = bin_f_statistic(shapelet_distances, T, num_of_ts);
                //printf("%u\t\t%g\n", shapelets_index, shapelet_candidate.quality);
                free(shapelet_distances);   //shapelet_distances is only used to measure quality
                // Store every shapelet of T[i] with its quality measure and length in the format [quality, length, shapelet] with shapelet = [s1, s2, ..., sl] 
                ts_shapelets[shapelets_index] = shapelet_candidate;
                shapelets_index++;
            }         
        }  // Here all shapelets from T[i] should have been stored together with its quality measures in ts_shapelets                                                             
        
        // Sort shapelets by quality
        qsort(ts_shapelets, (size_t) total_num_shapelets, sizeof(*ts_shapelets), compare_shapelets);
        
        // Remove self similar shapelets
        num_merged_shapelets = total_num_shapelets;
        ts_shapelets = remove_self_similars(ts_shapelets, &num_merged_shapelets);

        // Merge ts_shapelets with k_shapelets and keep only best k shapelets, destroying all total_num_shapelets in ts_shapelets
        merge_shapelets(k_shapelets, k, ts_shapelets, num_merged_shapelets);
        print_shapelets(k_shapelets, k);
        free(ts_shapelets);
    }
    
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

    //append k_shapelets and ts_shapelets into a single vector
    memcpy(all_shapelets, k_shapelets, k * sizeof(Shapelet));
    memcpy(&all_shapelets[k], ts_shapelets, ts_num_shapelets * sizeof(Shapelet));
    
    //sort merged vector by quality
    qsort(all_shapelets, (size_t) ts_num_shapelets, sizeof(*all_shapelets), compare_shapelets);

    //select only the k best shapelets from sorted vector
    memcpy(k_shapelets, all_shapelets, k * sizeof(Shapelet));

    free(all_shapelets);
}


// Get value of a shapelet at a specific position 
static inline numeric_type get_value(Shapelet *s, uint16_t j){
    return s->Ti[s->start_position + j];
}

static void fixedpt_print(fixedpt A){
	char num[20];

	fixedpt_str(A, num, -2);
	puts(num);
}

// Print all shapelets in a shapelet array
void print_shapelets(Shapelet * S, size_t num_shapelets){
    for(int i=0; i < num_shapelets; i++)
    {   
        #if USE_FLOAT == 1
        printf("%dth Shapelet has length: %d, quality: %g \nValues from timseries %p:\t", i, S[i].length, S[i].quality, S[i].Ti); 
        for(int j = 0; j < S[i].length; j++)
            printf("%g ", get_value(&S[i], j));
        printf("\n\n");
        
        #else
        printf("%dth Shapelet has length: %d, quality:", i, S[i].length);
        fixedpt_print(S[i].quality);
        printf("\nValues from timseries %p:\t", S[i].Ti); 
        for(int j = 0; j < S[i].length; j++)
            printf("%g ", get_value(&S[i], j));
        printf("\n\n");
            
        #endif
    }
}