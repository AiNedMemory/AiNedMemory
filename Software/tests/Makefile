VERBOSE=@
COLOR_GREEN="\033[1;32m"
COLOR_RED="\033[1;31m"
COLOR_BLUE="\033[1;34m"
COLOR_YELLOW="\033[1;33m"
COLOR_END="\033[0m"

CLEAN_PRINT=@echo ${COLOR_RED}Cleaning build files${COLOR_END}
GEN_PRINT=@echo ${COLOR_BLUE}\(Generating output\)${COLOR_END}
COMPARE_RINT=@echo ${COLOR_GREEN}\(Compare result\)${COLOR_END}


TESTS:=$(wildcard *.txt)
RESULTS:=$(TESTS:.txt=.txt.result)
CHECKS:=$(TESTS:.txt=.txt.check)

all: $(CHECKS)

$(RESULTS): ../src/main

%.txt.result: %.txt
	$(GEN_PRINT) $@
	$(VERBOSE) (cat $< | ../src/main > $@ 2>&1) || true


.phony: $(CHECKS)
%.txt.check: %.txt.result %.txt.output
	$(COMPARE_RINT) $^
	$(VERBOSE) diff $^  -q


clean:
	$(CLEAN_PRINT)
	$(VERBOSE) rm -f $(RESULTS)

../src/main:
	$(VERBOSE) make -C ../src/
