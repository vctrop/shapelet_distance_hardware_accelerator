CC= gcc
ARMCC = arm-linux-gnueabi-gcc
CFLAGS= -lm -Wall -pthread -O2 -std=gnu99 #add -g for debugging
ARMFLAGS= -static -march=armv7-a -mtune=cortex-a9 -mfpu=neon -mfloat-abi=softfp 
ARITH=  -DUSE_FLOAT			#remove this flag to use fixed point arithmetic instead
OBJS= shapelet_transform.c extract_shapelets.c
TIMING_OBJS= shapelet_transform.c timing_test.c

all: print_debug_vector print_readable_debug_vector

# Uses zscore normaliztion and power of two in distance computation
print_debug_vector: $(OBJS)
	$(CC) $(ARITH) -DUSE_ZSCORE -o $@ $^   $(CFLAGS)

print_readable_debug_vector: $(OBJS)
	$(CC) $(ARITH) -DUSE_ZSCORE -DREADABLE_VECTOR -o $@ $^   $(CFLAGS)

.PHONY: clean
clean:
	$(RM) *.o extract_shapelets_zscore_pow 
.PHONY: clean_win
clean_win: 
	del *.o *.exe
