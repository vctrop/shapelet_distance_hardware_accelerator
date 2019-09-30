CC= gcc
CFLAGS= -lm
OBJS= shapelet_transform.o test_shapelets.o

all: test_shapelets
test_shapelets: $(OBJS)
	$(CC) -o $@ -c $@.c $(CFLAGS)

.PHONY: clean
clean:
	$(RM) *.o test_shapelets