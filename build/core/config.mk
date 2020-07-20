# mka builde will run preparee bacon and then finalizee
builde: preparee synce postsynce bacon finalizee
.PHONY: builde

# prepare & init e
preparee:
	$(BASH) vendor/e/src/init.sh

# force sync everything needed
synce:
	$(BASH) vendor/e/sync.sh

# special handling after sync, before actually build
postsynce:
	$(BASH) vendor/e/post-sync.sh

# final tasks after building e
finalizee:
	$(BASH) vendor/e/finalize.sh

# dirty build target without syncing the sources
dirtye: preparee postsynce bacon finalizee
.PHONY: dirtye
