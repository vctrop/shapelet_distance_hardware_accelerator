CC= gcc
CFLAGS= -lm -Wall -pthread -O2  -DUSE_FLOAT#-g #add -g for debugging
OBJS= shapelet_transform.o test_shapelets.o

all: test_shapelets.elf 
test_shapelets.elf: $(OBJS)
	$(CC) -o $@ $^  $(CFLAGS) 

.PHONY: clean
clean:
	$(RM) *.o *.elf
clean_win: 
	del *.o test_shapelets.exe