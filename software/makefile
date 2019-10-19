CC= gcc
CFLAGS= -lm -Wall #-g #add -g for debugging
OBJS= shapelet_transform.o test_shapelets.o

all: test_shapelets
test_shapelets: $(OBJS)
	$(CC) -o $@ $^ $(CFLAGS)

.PHONY: clean
clean:
	$(RM) *.o test_shapelets