CC = clang
FRAME = -framework CoreFoundation -framework Foundation
CFLAGS = -Wall -O3
ARCHS = -arch x86_64 -arch i386
TARGET = ytextract
SRC = main.m

.SILENT :

all : $(SRC)
	$(CC) -o $(TARGET) $(SRC) -ObjC $(FRAME) $(CFLAGS) $(ARCHS)

.PHONY : clean
clean :
	rm -f $(TARGET)
