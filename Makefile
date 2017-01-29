PRG=svgmerge
SRC=$(wildcard src/*.vala)

$(PRG): 	$(SRC)
	valac -o $@ $^ --pkg libxml-2.0 --pkg gio-2.0

	
