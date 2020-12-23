dav1d_wasm_release_build_path="build/dav1d-wasm-release"
dav1d_wasm_debug_build_path="build/dav1d-wasm-debug"
dav1d_native_release_build_path="build/dav1d-native-release"
dav1d_wasm_release_library_path="out/wasm/release/lib/libdav1d.a"
dav1d_wasm_debug_library_path="out/wasm/debug/lib/libdav1d.a"

all: dav1d.wasm

patch:
	patch -d dav1d -p1 <dav1d.patch

$(dav1d_wasm_release_library_path):
	meson dav1d $(dav1d_wasm_release_build_path) \
		--prefix="$(CURDIR)/out/wasm/release" \
		--libdir=lib \
		--cross-file=cross_file.txt \
		--default-library=static \
		--buildtype=release \
		-Dbitdepths="['8']" \
		-Dbuild_asm=false \
		-Dbuild_tools=false \
		-Dbuild_tests=false \
		-Dlogging=false \
	&& ninja -C $(dav1d_wasm_release_build_path) install

$(dav1d_wasm_debug_library_path):
	meson dav1d $(dav1d_wasm_debug_build_path) \
		--prefix="$(CURDIR)/out/wasm/debug" \
		--libdir=lib \
		--cross-file=cross_file.txt \
		--default-library=static \
		--buildtype=debug \
		-Dbitdepths="['8']" \
		-Dbuild_asm=false \
		-Dbuild_tools=false \
		-Dbuild_tests=false \
		-Dlogging=false \
	&& ninja -C $(dav1d_wasm_debug_build_path) install

out/native/release/tools/dav1d:
	meson dav1d $(dav1d_native_release_build_path) \
		--prefix="$(CURDIR)/out/native/release" \
		--libdir=lib \
		--default-library=static \
		--buildtype=release \
		-Dbitdepths="['8']" \
		-Dbuild_asm=true \
		-Dbuild_tools=true \
		-Dbuild_tests=false \
		-Dlogging=false \
	&& ninja -C $(dav1d_native_release_build_path) install

dav1d.wasm: $(dav1d_wasm_release_library_path) dav1d.c
	emcc $^ -DNDEBUG -O3 --llvm-lto 3 -Iout/wasm/release//include -Wl,--shared-memory,--no-check-features --no-entry -s STANDALONE_WASM=1 -o $@ \
		-s TOTAL_MEMORY=67108864 -s MALLOC=emmalloc

dav1d.debug.wasm: $(dav1d_wasm_debug_library_path) dav1d.c
	EMCC_DEBUG=2 emcc $^ -g4 -O0 -Iout/wasm/debug/include -Wl,--shared-memory,--no-check-features --no-entry -s STANDALONE_WASM=1 -o $@ \
		-s TOTAL_MEMORY=67108864 -s MALLOC=emmalloc


.PHONY: test
test: dav1d.c
	$(CC) $^ $(CFLAGS) -O2 -Wall -o $@ \
		-I../tmp/dav1d/dist/include -L../tmp/dav1d/dist/lib \
		-ldav1d -lpthread

test-debug: dav1d.c
	$(CC) $^ $(CFLAGS) -O0 -g -Wall -o $@ \
		-I../tmp/dav1d/dist/include -L../tmp/dav1d/dist/lib \
		-ldav1d -lpthread

test-native: test
	./test

test-valgrind: CFLAGS = -DDJS_VALGRIND
test-valgrind: test
	valgrind ./test

test-node: dav1d.wasm
	node --experimental-modules --preserve-symlinks test.mjs

clean: clean-build clean-wasm clean-test
clean-build:
	rm -rf build
clean-wasm:
	rm -f dav1d.wasm
clean-test:
	rm -f test
