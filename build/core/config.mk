# understanding PHONY and deps:
# https://www.gnu.org/software/make/manual/html_node/Phony-Targets.html

# mka eos build target
eos: preparee bacon finalizee
.PHONY: eos

# prepare e. TODO: MUST BE MOVED TO ANYWHERE ELSE - HERE IT IS TOO LATE!
preparee:
	@echo .
	@echo      '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
	@echo      '********                 /e/ - preparee                     ********'
	@echo -e   '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n'
ifeq ($(WITH_FDROID),true)
	$(BASH) cd vendor/fdroid && ./get_packages.sh
endif

# final tasks after building e
finalizee: preparee bacon
	@echo .
	@echo      '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
	@echo      '********               /e/ - finalizee                      ********'
	@echo -e   '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n'
	$(BASH) vendor/e/finalize.sh
