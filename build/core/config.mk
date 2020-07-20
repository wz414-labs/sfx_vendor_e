# mka builde will run preparee bacon and then finalizee
builde: preparee bacon finalizee
.PHONY: builde

# prepare & init e
preparee:
	$(BASH) vendor/e/src/init.sh

# force sync everything needed
synce:
	$(BASH) vendor/e/sync.sh


# final tasks after building e
finalizee:
	$(BASH) vendor/e/finalize.sh
