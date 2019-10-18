ROOT_DIR=${PWD}
DEST=$(ROOT_DIR)/dist
DEST_INCLUDE=$(DEST)/include

MAKE_FLAGS = -j8
CFLAGS += ${EXTRA_CFLAGS}
CXXFLAGS += ${EXTRA_CXXFLAGS}
LDFLAGS += $(EXTRA_LDFLAGS)
MACHINE ?= $(shell uname -m)
ARFLAGS = ${EXTRA_ARFLAGS} rs
STRIPFLAGS = -S -x

# Dependencies and Rocksdb
LZ4_COMMIT = e8baeca51ef2003d6c9ec21c32f1563fef1065b9
ZLIB_COMMIT = cacf7f1d4e3d44d871b605da3b647f07d718623f
SNAPPY_COMMIT = e9e11b84e629c3e06fbaa4f0a86de02ceb9d6992
ZSTD_COMMIT = 8b6d96827c24dd09109830272f413254833317d9
OPENSSL_COMMIT = 894da2fb7ed5d314ee5c2fc9fd2d9b8b74111596
SASL_COMMIT = 0189425cc210555c36383293c468df5da73acc48
RDKAFKA_COMMIT = 7aa9b3964f7b63aa355fb7ff3bfc44e39eac7195

deps: prepare zlib lz4 snappy zstd

default_target: deps rdkafka

.PHONY: prepare
prepare:
	rm -rf $(DEST)

.PHONY: zlib
zlib:
	git submodule update --remote --init --recursive -- libs/zlib
	cd libs/zlib && git checkout $(ZLIB_COMMIT)
	cd libs/zlib && CFLAGS='-fPIC -O2 ${EXTRA_CFLAGS}' LDFLAGS='${EXTRA_LDFLAGS}' ./configure --static && \
	$(MAKE) clean && $(MAKE) $(MAKE_FLAGS) all
	cp libs/zlib/libz.a $(DEST)/
	cp libs/zlib/*.h $(DEST_INCLUDE)/

.PHONY: lz4
lz4:
	git submodule update --remote --init --recursive -- libs/lz4
	cd libs/lz4 && git checkout $(LZ4_COMMIT)
	cd libs/lz4 && $(MAKE) clean && $(MAKE) $(MAKE_FLAGS) CFLAGS='-fPIC -O2 ${EXTRA_CFLAGS}' lz4 lz4-release
	cp libs/lz4/lib/liblz4.a $(DEST)/
	cp libs/lz4/lib/*.h $(DEST_INCLUDE)/

.PHONY: snappy
snappy:
	git submodule update --remote --init --recursive -- libs/snappy
	cd libs/snappy && git checkout $(SNAPPY_COMMIT)
	cd libs/snappy && rm -rf build && mkdir -p build && cd build && \
	CFLAGS='-O2 ${EXTRA_CFLAGS}' CXXFLAGS='-O2 ${EXTRA_CXXFLAGS}' LDFLAGS='${EXTRA_LDFLAGS}' cmake -DCMAKE_POSITION_INDEPENDENT_CODE=ON .. && \
	$(MAKE) clean && $(MAKE) $(MAKE_FLAGS) snappy
	cp libs/snappy/build/libsnappy.a $(DEST)/
	cp libs/snappy/*.h $(DEST_INCLUDE)/

.PHONY: zstd
zstd:
	git submodule update --remote --init --recursive -- libs/zstd
	cd libs/zstd && git checkout $(ZSTD_COMMIT)
	cd libs/zstd/lib && $(MAKE) clean && DESTDIR=. PREFIX= $(MAKE) $(MAKE_FLAGS) CFLAGS='-fPIC -O2 ${EXTRA_CFLAGS}' all install
	cp libs/zstd/lib/libzstd.a $(DEST)/
	cp libs/zstd/lib/include/*.h $(DEST_INCLUDE)/
