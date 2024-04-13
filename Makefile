.PHONY: clean run release

TARGET=hexdec

all: hexdec.asm
	nasm -O0 -g -felf64 $^ -o $(TARGET).o
	ld -g $(TARGET).o -o $(TARGET)

release: hexdec.asm
	nasm -felf64 $^ -o $(TARGET).o
	ld -O3 -flto $(TARGET).o -o $(TARGET)
	strip $(TARGET)

clean:
	-rm -f hexdec.o hexdec

run: all
	./hexdec
