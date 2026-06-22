BENCHMARKS := median multiply memcpy branch
XSIM_DIR   := ../riscv_soc.sim/sim_1/behav/xsim

.PHONY: all clean $(BENCHMARKS) $(addprefix install-,$(BENCHMARKS))

all: $(BENCHMARKS)

$(BENCHMARKS):
	$(MAKE) -C $@ all

clean:
	for d in $(BENCHMARKS); do $(MAKE) -C $$d clean; done

# install-<name> copies that benchmark's text.dat to the xsim directory
$(addprefix install-,$(BENCHMARKS)): install-%:
	$(MAKE) -C $* install

.PHONY: sizes
sizes: all
	@for d in $(BENCHMARKS); do \
	  words=$$(wc -l < $$d/text.dat); \
	  printf "%-12s %4d words (%d bytes)\n" $$d $$words $$((words*4)); \
	done
