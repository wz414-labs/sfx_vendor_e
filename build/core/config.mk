# understanding PHONY and deps:
# https://www.gnu.org/software/make/manual/html_node/Phony-Targets.html

# mka eos-fresh will run preparee, synce, postsynce bacon and then finalizee
# note: the order here is not important, each target sets its dependency
# which then ensures the proper order processing
eos-fresh: preparee synce postsynce bacon finalizee
.PHONY: eos-fresh

# mka eos build target without syncing the sources
eos: preparee postsync-nosync bacon finalize-nosync
.PHONY: eos

# prepare & init e
preparee:
ifeq ($(WITH_FDROID),true)
	$(BASH) cd vendor/fdroid && ./get_packages.sh
endif
	$(BASH) vendor/e/src/init.sh

# force sync everything needed
synce: preparee
	$(BASH) vendor/e/sync.sh

# special handling after sync, before actually build
postsynce: preparee synce
	$(BASH) vendor/e/post-sync.sh

postsync-nosync: preparee
	$(BASH) vendor/e/post-sync.sh

# final tasks after building e
finalizee: preparee postsynce bacon
	$(BASH) vendor/e/finalize.sh

finalize-nosync: preparee postsync-nosync bacon
	$(BASH) vendor/e/finalize.sh
