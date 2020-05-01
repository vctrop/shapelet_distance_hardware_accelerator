CC= gcc
ARMCC = arm-linux-gnueabi-gcc
CFLAGS= -lm -Wall -pthread -O2 -std=gnu99 #add -g for debugging
ARITH=  -DUSE_FLOAT			#remove this flag to use fixed point arithmetic instead
OBJS= shapelet_transform.c extract_shapelets.c
TIMING_OBJS= shapelet_transform.c timing_test.c

all: count_early_abandons

# Uses zscore normaliztion and power of two in distance computation
count_early_abandons: $(OBJS)
	$(CC) $(ARITH) -DUSE_ZSCORE -DNUM_PU=4 -o $@ $^   $(CFLAGS)

.PHONY: clean
clean:
	$(RM) *.o count_early_abandons 
.PHONY: clean_win
clean_win: 
	del *.o *.exe
