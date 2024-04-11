.PHONY: clean

hexdec: hexdec.asm
	nasm -felf64 $^ -o $@.o && ld $@.o -o $@

clean:
	-rm -rf hexdec.o hexdec
