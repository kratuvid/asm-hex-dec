.PHONY: clean run release debug

TARGET=hexdec

all: debug

debug: $(TARGET).asm
	nasm -O0 -g -felf64 $^ -o $(TARGET).o
	ld -g $(TARGET).o -o $(TARGET)

release: $(TARGET).asm
	nasm -felf64 $^ -o $(TARGET).o
	ld -O3 -flto $(TARGET).o -o $(TARGET)
	strip $(TARGET)

clean:
	-rm -f $(TARGET).o $(TARGET)

run: all
	./$(TARGET)
