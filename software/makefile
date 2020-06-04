CC= gcc
ARMCC = arm-linux-gnueabi-gcc
CFLAGS= -lm -Wall -pthread -O3 -std=gnu99 #add -g for debugging
ARMFLAGS= -static -march=armv7-a -mtune=cortex-a9 -mfpu=neon -mfloat-abi=softfp 
ARITH=  -DUSE_FLOAT			#remove this flag to use fixed point arithmetic instead
OBJS= shapelet_transform.c extract_shapelets.c
TIMING_OBJS= shapelet_transform.c timing_test.c

all: extract_shapelets_zscore_pow

# uses zscore normaliztion and power of two in distance computation
extract_shapelets_zscore_pow: $(OBJS)
	$(CC) $(ARITH) -DUSE_ZSCORE -o $@ $^   $(CFLAGS) -fopenmp

#THESE OTHER COMPILATION COMMANDS WHERE USED DURING TESTING AND ARE DEPRECATED:
#all: extract_shapelets_algebric_pow extract_shapelets_algebric_abs extract_shapelets_zscore_pow extract_shapelets_zscore_abs

# uses algebric normalization and power of two in distance computation
extract_shapelets_algebric_pow: $(OBJS)
	$(CC) $(ARITH) -o $@ $^  $(CFLAGS) 

# uses algebric normalization and abs in distance computation 
extract_shapelets_algebric_abs: $(OBJS)
	$(CC) $(ARITH) -DUSE_ABS -o $@ $^   $(CFLAGS)
    

# uses zscore normalization and abs in distance computation
extract_shapelets_zscore_abs: $(OBJS)
	$(CC) $(ARITH) -DUSE_ZSCORE -DUSE_ABS -o $@ $^   $(CFLAGS)
    
extract_shapelets_zscore_abs_exp: $(OBJS)
	$(CC) $(ARITH) -DUSE_ZSCORE -DUSE_ABS -DUSE_EXPECTED_VALUE  -o  $@  $^  $(CFLAGS)

# arm cross compilation used for simulation. Requires arm gcc cross compiler. 
arm: timing3 timing10 timing20 timing30 timing40 timing50 timing80 timing100 timing127 

timing3: $(TIMING_OBJS)
	$(ARMCC) $(ARMFLAGS) $(ARITH) -DUSE_ZSCORE -DLENGTH=3 -o $@ $^   $(CFLAGS)
timing10: $(TIMING_OBJS)
	$(ARMCC) $(ARMFLAGS) $(ARITH) -DUSE_ZSCORE -DLENGTH=10 -o $@ $^   $(CFLAGS)
timing20: $(TIMING_OBJS)
	$(ARMCC) $(ARMFLAGS) $(ARITH) -DUSE_ZSCORE -DLENGTH=20 -o $@ $^   $(CFLAGS)
timing30: $(TIMING_OBJS)
	$(ARMCC) $(ARMFLAGS) $(ARITH) -DUSE_ZSCORE -DLENGTH=30 -o $@ $^   $(CFLAGS)
timing40: $(TIMING_OBJS)
	$(ARMCC) $(ARMFLAGS) $(ARITH) -DUSE_ZSCORE -DLENGTH=40 -o $@ $^   $(CFLAGS)
timing50: $(TIMING_OBJS)
	$(ARMCC) $(ARMFLAGS) $(ARITH) -DUSE_ZSCORE -DLENGTH=50 -o $@ $^   $(CFLAGS)
timing80: $(TIMING_OBJS)
	$(ARMCC) $(ARMFLAGS) $(ARITH) -DUSE_ZSCORE -DLENGTH=80 -o $@ $^   $(CFLAGS)
timing100: $(TIMING_OBJS)
	$(ARMCC) $(ARMFLAGS) $(ARITH) -DUSE_ZSCORE -DLENGTH=100 -o $@ $^   $(CFLAGS)
timing127: $(TIMING_OBJS)
	$(ARMCC) $(ARMFLAGS) $(ARITH) -DUSE_ZSCORE -DLENGTH=127 -o $@ $^   $(CFLAGS)

.PHONY: clean
clean:
	$(RM) *.o extract_shapelets_algebric_pow extract_shapelets_algebric_abs extract_shapelets_zscore_pow extract_shapelets_zscore_abs extract_shapelets_zscore_abs_exp 
.PHONY: clean_win
clean_win: 
	del *.o *.exe
