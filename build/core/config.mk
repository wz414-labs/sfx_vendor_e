# understanding PHONY and deps:
# https://www.gnu.org/software/make/manual/html_node/Phony-Targets.html

# mka eos build target
eos: preparee bacon finalizee
.PHONY: eos

# prepare e. TODO: MUST BE MOVED TO ANYWHERE ELSE - HERE IT IS TOO LATE!
.PHONY: preparee
preparee:
	@echo .
	@echo      '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
	@echo      '********                 /e/ - prepare                      ********'
	@echo -e   '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n'
ifeq ($(WITH_FDROID),true)
	$(BASH) cd vendor/fdroid && ./get_packages.sh
endif

# final tasks after building e
.PHONY: finalizee
finalizee: preparee bacon
	@echo .
	@echo      '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
	@echo      '********               /e/ - finalize                       ********'
	@echo -e   '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n'
	$(BASH) vendor/e/finalize.sh
