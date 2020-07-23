# understanding PHONY and deps:
# https://www.gnu.org/software/make/manual/html_node/Phony-Targets.html

# mka builde will run preparee bacon and then finalizee
eos: preparee synce postsynce bacon finalizee
.PHONY: builde

# dirty build target without syncing the sources
eos-nosync: preparee postsync-nosync bacon finalize-nosync
.PHONY: eos-nosync

# prepare & init e
preparee:
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
