# mka builde will run preparee bacon and then finalizee
builde: preparee bacon finalizee
.PHONY: builde

# prepare & init e
preparee:
	$(BASH) vendor/e/src/init.sh
	$(BASH) vendor/e/build-pretasks.sh

# final tasks after building e
finalizee:
	$(BASH) vendor/e/finalize.sh
