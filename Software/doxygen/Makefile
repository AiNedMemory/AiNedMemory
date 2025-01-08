SOURCES:=$(wildcard ../src/*.c) $(wildcard ../src/*.h) 

all: ../documentation/html/index.html

../documentation/html/index.html: ${SOURCES}
	doxygen doxy


clean:
	rm -rf ../documentation/
