.PHONY: all clean

SRC=$(wildcard *.s)
BIN=$(SRC:%.s=out/%.bin)

all: out $(BIN)

out:
	mkdir -p out

out/%.bin: %.s
	ca65 -g $^ -o out/$*.o -l out/$*.lst --list-bytes 0
	ld65 -o $@ -Ln out/$*.labels -m out/$*.map -C sdk/ue14500.cfg out/$*.o

clean:
	rm -rf out