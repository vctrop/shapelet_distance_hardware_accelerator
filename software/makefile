CC= gcc
CFLAGS= -lm -Wall #-g #add -g for debugging
OBJS= shapelet_transform.o test_shapelets.o

all: test_shapelets
test_shapelets: $(OBJS)
	$(CC) -o $@ $^ $(CFLAGS)

.PHONY: clean
clean:
	$(RM) *.o test_shapelets

# all: test_shapelets_float test_shapelets_fixed  
# test_shapelets_float: $(OBJS)
	# $(CC) -o $@ $^ -DUSE_FLOAT=1 $(CFLAGS)
# test_shapelets_fixed: $(OBJS)
	# $(CC) -o $@ $^ -DUSE_FLOAT=0 $(CFLAGS)
