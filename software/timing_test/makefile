ARMCC 		= arm-linux-gnueabi-gcc
CFLAGS 		= -lm -Wall -pthread -O2 -std=gnu99 #add -g for debugging
ARITH		=  -DUSE_FLOAT		
# --- ARM objects used in $make arm 
TIMING_OBJS	= shapelet_transform.c timing_test.c 
ARMFLAGS	= -static -march=armv7-a -mtune=cortex-a9 -mfpu=neon -mfloat-abi=softfp 

# arm cross compilation used for simulation. Requires arm gcc cross compiler. 
all: timing3 timing10 timing20 timing30 timing40 timing50 timing60 timing70 timing80 timing90 timing100 timing110 timing120 timing128 

timing3: $(TIMING_OBJS)
	$(ARMCC) $(ARMFLAGS) $(ARITH) -DUSE_ZSCORE -DLENGTH=3 -o $@ $^   $(CFLAGS)
timing10: $(TIMING_OBJS)
	$(ARMCC) $(ARMFLAGS) $(ARITH) -DUSE_ZSCORE -DLENGTH=10 -o $@ $^   $(CFLAGS)
timing20: $(TIMING_OBJS)
	$(ARMCC) $(ARMFLAGS) $(ARITH) -DUSE_ZSCORE -DLENGTH=20 -o $@ $^   $(CFLAGS)
timing30: $(TIMING_OBJS)
	$(ARMCC) $(ARMFLAGS) $(ARITH) -DUSE_ZSCORE -DLENGTH=30 -o $@ $^   $(CFLAGS)
timing40: $(TIMING_OBJS)
	$(ARMCC) $(ARMFLAGS) $(ARITH) -DUSE_ZSCORE -DLENGTH=40 -o $@ $^   $(CFLAGS)
timing50: $(TIMING_OBJS)
	$(ARMCC) $(ARMFLAGS) $(ARITH) -DUSE_ZSCORE -DLENGTH=50 -o $@ $^   $(CFLAGS)
timing60: $(TIMING_OBJS)
	$(ARMCC) $(ARMFLAGS) $(ARITH) -DUSE_ZSCORE -DLENGTH=60 -o $@ $^   $(CFLAGS)
timing70: $(TIMING_OBJS)
	$(ARMCC) $(ARMFLAGS) $(ARITH) -DUSE_ZSCORE -DLENGTH=70 -o $@ $^   $(CFLAGS)
timing80: $(TIMING_OBJS)
	$(ARMCC) $(ARMFLAGS) $(ARITH) -DUSE_ZSCORE -DLENGTH=80 -o $@ $^   $(CFLAGS)
timing90: $(TIMING_OBJS)
	$(ARMCC) $(ARMFLAGS) $(ARITH) -DUSE_ZSCORE -DLENGTH=90 -o $@ $^   $(CFLAGS)
timing100: $(TIMING_OBJS)
	$(ARMCC) $(ARMFLAGS) $(ARITH) -DUSE_ZSCORE -DLENGTH=100 -o $@ $^   $(CFLAGS)
timing110: $(TIMING_OBJS)
	$(ARMCC) $(ARMFLAGS) $(ARITH) -DUSE_ZSCORE -DLENGTH=110 -o $@ $^   $(CFLAGS)
timing120: $(TIMING_OBJS)
	$(ARMCC) $(ARMFLAGS) $(ARITH) -DUSE_ZSCORE -DLENGTH=120 -o $@ $^   $(CFLAGS)
timing128: $(TIMING_OBJS)
	$(ARMCC) $(ARMFLAGS) $(ARITH) -DUSE_ZSCORE -DLENGTH=128 -o $@ $^   $(CFLAGS)

.PHONY: clean
clean:
	$(RM) *.o ../bin/*
.PHONY: clean_win
clean_win: 
	del *.o *.exe
