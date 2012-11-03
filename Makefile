FRAME = -framework CoreFoundation -framework Foundation
CFLAGS = -Wall -O2
ARCHS = -arch x86_64 -arch i386

all:
	clang -o ytextract main.m -ObjC $(FRAME) $(CFLAGS) $(ARCHS)

clean:
	rm -rf ytextract
