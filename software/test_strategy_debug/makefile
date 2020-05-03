CC= gcc
ARMCC = arm-linux-gnueabi-gcc
CFLAGS= -lm -Wall -pthread -O2 -std=gnu99 #add -g for debugging
ARITH=  -DUSE_FLOAT			#remove this flag to use fixed point arithmetic instead
OBJS= shapelet_transform.c extract_shapelets.c

all: print_debug_vector print_readable_debug_vector

# Uses zscore normaliztion and power of two in distance computation
print_debug_vector: $(OBJS)
	$(CC) $(ARITH) -DUSE_ZSCORE -DNUM_PU=4 -o $@ $^   $(CFLAGS)

print_readable_debug_vector: $(OBJS)
	$(CC) $(ARITH) -DUSE_ZSCORE -DREADABLE_VECTOR -DNUM_PU=4 -o $@ $^   $(CFLAGS)

.PHONY: clean
clean:
	$(RM) *.o print_debug_vector  print_readable_debug_vector
.PHONY: clean_win
clean_win: 
	del *.o *.exe
