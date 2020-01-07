CC= gcc
CFLAGS= -lm -Wall -pthread -O2 -std=gnu99 #add -g for debugging
ARITH=  -DUSE_FLOAT			#remove this flag to use fixed point arithmetic instead
OBJS= shapelet_transform.c test_shapelets.c

all: test_shapelets_algebric_pow test_shapelets_algebric_abs test_shapelets_zscore_pow test_shapelets_zscore_abs

# uses algebric normalization and power of two in distance computation
test_shapelets_algebric_pow: $(OBJS)
	$(CC) $(ARITH) -o $@ $^  $(CFLAGS) 

# uses algebric normalization and abs in distance computation 
test_shapelets_algebric_abs: $(OBJS)
	$(CC) $(ARITH) -DUSE_ABS -o $@ $^   $(CFLAGS)
    
    
# uses zscore normaliztion and power of two in distance computation
test_shapelets_zscore_pow: $(OBJS)
	$(CC) $(ARITH) -DUSE_ZSCORE -o $@ $^   $(CFLAGS)

# uses zscore normalization and abs in distance computation
test_shapelets_zscore_abs: $(OBJS)
	$(CC) $(ARITH) -DUSE_ZSCORE -DUSE_ABS -o $@ $^   $(CFLAGS)
    

.PHONY: clean
clean:
	$(RM) *.o test_shapelets_algebric_pow test_shapelets_algebric_abs test_shapelets_zscore_pow test_shapelets_zscore_abs
.PHONY: clean_win
clean_win: 
	del *.o test_shapelets_algebric_pow.exe test_shapelets_algebric_abs.exe test_shapelets_zscore_pow.exe test_shapelets_zscore_abs.exe