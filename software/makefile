CC= gcc
CFLAGS= -lm -Wall -pthread -O2 #add -g for debugging
ARITH=  -DUSE_FLOAT			#remove this flag to use fixed point arithmetic instead
OBJS= shapelet_transform.c test_shapelets.c

all: test_shapelets_algebric_norm test_shapelets_zscore_norm test_shapelets_abs
#uses algebric normalization
test_shapelets_algebric_norm: $(OBJS)
	$(CC) $(ARITH) -o $@ $^  $(CFLAGS) 

#uses zscore normaliztion
test_shapelets_zscore_norm: $(OBJS)
	$(CC) $(ARITH) -DUSE_ZSCORE -o $@ $^   $(CFLAGS)

#uses abs function instead of square during distance calculation
test_shapelets_abs: $(OBJS)
	$(CC) $(ARITH) -DUSE_ABS -o $@ $^   $(CFLAGS)

.PHONY: clean
clean:
	$(RM) *.o test_shapelets_algebric_norm test_shapelets_zscore_norm test_shapelets_abs
clean_win: 
	del *.o test_shapelets.exe