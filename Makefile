
MERE_MEMORY_WASM	= target/wasm32-unknown-unknown/release/mere_memory_api.wasm
CORE_WASM		= target/wasm32-unknown-unknown/release/mere_memory.wasm
STORAGE_DNA		= packs/dna/storage.dna
STORAGE_APP		= packs/app/Storage.happ
STORAGE_APP_CLONABLE	= packs/app_clonable/Storage.happ

#
# Project
#
mere-memory-zome:	$(MERE_MEMORY_WASM)
rust_comile_fix:
	touch mere_memory_types/src/lib.rs # force rebuild otherwise rust fails

$(MERE_MEMORY_WASM):	Cargo.toml src/*.rs mere_memory_types/Cargo.toml mere_memory_types/src/*.rs flake.lock
	@echo "Building zome: $@"; \
	RUST_BACKTRACE=1 CARGO_TARGET_DIR=target cargo build \
		--release --target wasm32-unknown-unknown
	@touch $@ # Cargo must have a cache somewhere because it doesn't update the file time

$(CORE_WASM):		mere_memory/Cargo.toml mere_memory/src/*.rs flake.lock  mere_memory_types/Cargo.toml mere_memory_types/src/*.rs
	make rust_comile_fix;
	@echo "Building zome: $@"; \
	cd mere_memory; RUST_BACKTRACE=1 CARGO_TARGET_DIR=../target cargo build \
		--release --target wasm32-unknown-unknown

$(STORAGE_DNA):			$(CORE_WASM) $(MERE_MEMORY_WASM) packs/dna/dna.yaml Cargo.toml mere_memory_types/Cargo.toml mere_memory_types/src/*.rs
	hc dna pack packs/dna/
$(STORAGE_APP):			$(STORAGE_DNA) packs/app/happ.yaml
	hc app pack packs/app/
$(STORAGE_APP_CLONABLE):	$(STORAGE_DNA) packs/app_clonable/happ.yaml
	hc app pack packs/app_clonable/

npm-reinstall-local:
	cd tests; npm uninstall $(NPM_PACKAGE); npm i --save $(LOCAL_PATH)
npm-reinstall-public:
	cd tests; npm uninstall $(NPM_PACKAGE); npm i --save $(NPM_PACKAGE)
npm-use-app-interface-client-public:
npm-use-app-interface-client-local:
npm-use-app-interface-client-%:
	NPM_PACKAGE=@spartan-hc/app-interface-client LOCAL_PATH=../../app-interface-client-js make npm-reinstall-$*
npm-use-backdrop-public:
npm-use-backdrop-local:
npm-use-backdrop-%:
	NPM_PACKAGE=@spartan-hc/holochain-backdrop LOCAL_PATH=../../node-holochain-backdrop make npm-reinstall-$*



#
# Packages
#
preview-crate:			test-debug
	cd mere_memory_types; cargo publish --dry-run --allow-dirty
publish-crate:			test-debug .cargo/credentials
	cd mere_memory_types; cargo publish
.cargo/credentials:
	cp ~/$@ $@



#
# Testing
#
tests/package-lock.json:	tests/package.json
	touch $@
tests/node_modules:		tests/package-lock.json
	cd tests; npm install
	touch $@
test:			$(STORAGE_APP) tests/node_modules
	cd tests; LOG_LEVEL=fatal npx mocha integration/test_api.js
test-debug:		$(STORAGE_APP) tests/node_modules
	cd tests; LOG_LEVEL=trace npx mocha integration/test_api.js



#
# Documentation
#
test-docs:
	cd mere_memory_types; cargo test --doc
build-docs:			test-docs
	cd mere_memory_types; cargo doc

PRE_HDK_VERSION = "=0.2.1"
NEW_HDK_VERSION = "=0.2.2"

PRE_HDI_VERSION = "=0.3.1"
NEW_HDI_VERSION = "=0.3.2"

GG_REPLACE_LOCATIONS = ':(exclude)*.lock' Cargo.toml mere_memory_types/ mere_memory/

update-hdk-version:
	git grep -l '$(PRE_HDK_VERSION)' -- $(GG_REPLACE_LOCATIONS) | xargs sed -i 's|$(PRE_HDK_VERSION)|$(NEW_HDK_VERSION)|g'
update-hdi-version:
	git grep -l '$(PRE_HDI_VERSION)' -- $(GG_REPLACE_LOCATIONS) | xargs sed -i 's|$(PRE_HDI_VERSION)|$(NEW_HDI_VERSION)|g'



#
# Repository
#
clean-remove-chaff:
	@find . -name '*~' -exec rm {} \;
clean-files:		clean-remove-chaff
	git clean -nd
clean-files-force:	clean-remove-chaff
	git clean -fd
clean-files-all:	clean-remove-chaff
	git clean -ndx
clean-files-all-force:	clean-remove-chaff
	git clean -fdx



#
# NPM packaging
#
prepare-zomelets-package:
	cd zomelets; rm -f dist/*
	cd zomelets; npx webpack
	cd zomelets; MODE=production npx webpack
	cd zomelets; gzip -kf dist/*.js
preview-zomelets-package:	clean-files test prepare-zomelets-package
	cd zomelets; npm pack --dry-run .
create-zomelets-package:	clean-files test prepare-zomelets-package
	cd zomelets; npm pack .
publish-zomelets-package:	clean-files test prepare-zomelets-package
	cd zomelets; npm publish --access public .
