# understanding PHONY and deps:
# https://www.gnu.org/software/make/manual/html_node/Phony-Targets.html
# https://swcarpentry.github.io/make-novice/reference.html

# ensure that we fetch F-Droid packages at very first
#ifeq ($(WITH_FDROID),true)
#GETPKGS := $(OUT_DIR)/get_packages
#GETPKGS : get_packages

#.PHONY: $(OUT_DIR)/get_packages
#.PHONY: get_packages
#$(OUT_DIR)/get_packages:
#get_packages:
#	@echo "preparing /e/"
#	$(BASH) vendor/fdroid/get_packages.sh vendor/fdroid 9.9.9.9
#	@touch $@

#ifneq (0, $(GETPKGS))
#$(error $(GETPKGS))
#endif
#endif # WITH_FDROID

# mka eos build target
.PHONY: eos
eos: builde

# final tasks after building e
.PHONY: builde
builde: bacon
	$(hide) @echo .
	$(hide) @echo      '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
	$(hide) @echo      '********               /e/ - finalize                       ********'
	$(hide) @echo -e   '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n'
	$(hide) $(BASH) vendor/e/finalize.sh
