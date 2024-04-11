.PHONY: clean

hexdec: hexdec.asm
	nasm -g -felf64 $^ -o $@.o && ld -g $@.o -o $@

clean:
	-rm -rf hexdec.o hexdec
