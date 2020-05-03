CC= gcc
ARMCC = arm-linux-gnueabi-gcc
CFLAGS= -lm -Wall -pthread -O2 -std=gnu99 #add -g for debugging
ARITH=  -DUSE_FLOAT			#remove this flag to use fixed point arithmetic instead
OBJS= shapelet_transform.c fstat_from_file.c

all: fstat_from_file

# Uses zscore normaliztion and power of two in distance computation
fstat_from_file: $(OBJS)
	$(CC) $(ARITH) -DUSE_ZSCORE -o $@ $^   $(CFLAGS)

.PHONY: clean
clean:
	$(RM) *.o fstat_from_file
.PHONY: clean_win
clean_win: 
	del *.o *.exe
