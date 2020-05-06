CC= gcc
ARMCC = arm-linux-gnueabi-gcc
CFLAGS= -lm -Wall -pthread -O2 -std=gnu99 #add -g for debugging
ARITH=  -DUSE_FLOAT			#remove this flag to use fixed point arithmetic instead
OBJS_FSTAT = shapelet_transform.c fstat_from_file.c
OBJS_DISTS = shapelet_transform.c extract_sw_distances.c

all: fstat_from_file extract_sw_distances

# Uses zscore normaliztion and power of two in distance computation
fstat_from_file: $(OBJS_FSTAT)
	$(CC) $(ARITH) -DUSE_ZSCORE -o $@ $^   $(CFLAGS)
    
# Uses zscore normaliztion and power of two in distance computation
extract_sw_distances: $(OBJS_DISTS)
	$(CC) $(ARITH) -DUSE_ZSCORE -o $@ $^   $(CFLAGS)

.PHONY: clean
clean:
	$(RM) *.o fstat_from_file extract_sw_distances
.PHONY: clean_win
clean_win: 
	del *.o *.exe
