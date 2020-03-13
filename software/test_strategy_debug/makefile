CC= gcc
ARMCC = arm-linux-gnueabi-gcc
CFLAGS= -lm -Wall -pthread -O2 -std=gnu99 #add -g for debugging
ARITH=  -DUSE_FLOAT			#remove this flag to use fixed point arithmetic instead
OBJS= shapelet_transform.c extract_shapelets.c
TIMING_OBJS= shapelet_transform.c timing_test.c
#all: extract_shapelets_algebric_pow extract_shapelets_algebric_abs extract_shapelets_zscore_pow extract_shapelets_zscore_abs
all: extract_shapelets_zscore_pow

# uses algebric normalization and power of two in distance computation
extract_shapelets_algebric_pow: $(OBJS)
	$(CC) $(ARITH) -o $@ $^  $(CFLAGS) 

# uses algebric normalization and abs in distance computation 
extract_shapelets_algebric_abs: $(OBJS)
	$(CC) $(ARITH) -DUSE_ABS -o $@ $^   $(CFLAGS)
    
# uses zscore normaliztion and power of two in distance computation
extract_shapelets_zscore_pow: $(OBJS)
	$(CC) $(ARITH) -DUSE_ZSCORE -o $@ $^   $(CFLAGS)

# uses zscore normalization and abs in distance computation
extract_shapelets_zscore_abs: $(OBJS)
	$(CC) $(ARITH) -DUSE_ZSCORE -DUSE_ABS -o $@ $^   $(CFLAGS)
    
extract_shapelets_zscore_pow_exp: $(OBJS)
	$(CC) $(ARITH) -DUSE_ZSCORE -DUSE_EXPECTED_VALUE  -o  $@  $^  $(CFLAGS)


.PHONY: clean
clean:
	$(RM) *.o extract_shapelets_algebric_pow extract_shapelets_algebric_abs extract_shapelets_zscore_pow extract_shapelets_zscore_abs extract_shapelets_zscore_abs_exp
.PHONY: clean_win
clean_win: 
	del *.o extract_shapelets_algebric_pow.exe extract_shapelets_algebric_abs.exe extract_shapelets_zscore_pow.exe extract_shapelets_zscore_abs.exe extract_shapelets_zscore_abs_exp.exe