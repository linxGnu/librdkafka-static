ROOT_DIR=${PWD}
DEST=$(ROOT_DIR)/dist
DEST_LIB=$(DEST)/lib
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

SASL_OPTS = --enable-static=yes --enable-shared=no --prefix=$(ROOT_DIR)/libs/sasl/build/ --with-pic

default: prepare zlib lz4 snappy zstd sasl openssl rdkafka

.PHONY: prepare
prepare:
	rm -rf $(DEST)
	mkdir -p $(DEST_LIB) $(DEST_INCLUDE)

.PHONY: zlib
zlib:
	git submodule update --remote --init --recursive -- libs/zlib
	cd libs/zlib && git checkout $(ZLIB_COMMIT)
	cd libs/zlib && CFLAGS='-fPIC -O2 ${EXTRA_CFLAGS}' ./configure --static && \
	$(MAKE) clean && $(MAKE) $(MAKE_FLAGS) all
	cp libs/zlib/libz.a $(DEST_LIB)/
	cp libs/zlib/*.h $(DEST_INCLUDE)/

.PHONY: lz4
lz4:
	git submodule update --remote --init --recursive -- libs/lz4
	cd libs/lz4 && git checkout $(LZ4_COMMIT)
	cd libs/lz4 && $(MAKE) clean && $(MAKE) $(MAKE_FLAGS) CFLAGS='-fPIC -O2 ${EXTRA_CFLAGS}' lz4 lz4-release
	cp libs/lz4/lib/liblz4.a $(DEST_LIB)/
	cp libs/lz4/lib/*.h $(DEST_INCLUDE)/

.PHONY: snappy
snappy:
	git submodule update --remote --init --recursive -- libs/snappy
	cd libs/snappy && git checkout $(SNAPPY_COMMIT)
	cd libs/snappy && rm -rf build && mkdir -p build && cd build && \
	CFLAGS='-O2 ${EXTRA_CFLAGS}' cmake -DCMAKE_POSITION_INDEPENDENT_CODE=ON .. && \
	$(MAKE) clean && $(MAKE) $(MAKE_FLAGS) snappy
	cp libs/snappy/build/libsnappy.a $(DEST_LIB)/
	cp libs/snappy/*.h $(DEST_INCLUDE)/

.PHONY: zstd
zstd:
	git submodule update --remote --init --recursive -- libs/zstd
	cd libs/zstd && git checkout $(ZSTD_COMMIT)
	cd libs/zstd/lib && $(MAKE) clean && DESTDIR=. PREFIX= $(MAKE) $(MAKE_FLAGS) CFLAGS='-fPIC -O2 ${EXTRA_CFLAGS}' all install
	cp libs/zstd/lib/libzstd.a $(DEST_LIB)/
	cp libs/zstd/lib/include/*.h $(DEST_INCLUDE)/

.PHONY: sasl
sasl:
	git submodule update --remote --init --recursive -- libs/sasl
	cd libs/sasl && git checkout $(SASL_COMMIT)
	cd libs/sasl && sh autogen.sh $(SASL_OPTS) && ./configure $(SASL_OPTS) && $(MAKE) $(MAKE_FLAGS) install
	cp -R libs/sasl/build/lib/* $(DEST_LIB)/
	cp -R libs/sasl/build/include/* $(DEST_INCLUDE)/

.PHONY: openssl
openssl:
	git submodule update --remote --init --recursive -- libs/openssl
	cd libs/openssl && git checkout $(OPENSSL_COMMIT)
	cd libs/openssl && ./config no-dso no-shared zlib CFLAGS='-fPIC -O2 -Wl,--allow-multiple-definition ${EXTRA_CFLAGS}' --release --prefix=$(ROOT_DIR)/libs/openssl/build/ && \
	$(MAKE) $(MAKE_FLAGS) && $(MAKE) $(MAKE_FLAGS) install
	cp -R libs/openssl/build/lib/* $(DEST_LIB)/
	cp -R libs/openssl/build/include/* $(DEST_INCLUDE)/

.PHONY: rdkafka
rdkafka:
	git submodule update --remote --init --recursive -- libs/rdkafka
	cd libs/rdkafka && git checkout $(RDKAFKA_COMMIT)
	cd libs/rdkafka && $(MAKE) clean && mkdir build && \
	./configure --libdir=$(DEST_LIB) --includedir=$(DEST_INCLUDE) \
	--prefix=$(ROOT_DIR)/libs/rdkafka/build \
	--CPPFLAGS="-fPIC -O2 -Wl,--allow-multiple-definition -Wl,-rpath" \
	--disable-shared --no-cache --enable-static --enable-zstd --enable-sasl \
	--enable-ssl --enable-gssapi --enable-lz4-ext --enable-c11threads --disable-debug-symbols
	cd libs/rdkafka && \
	$(MAKE) $(MAKE_FLAGS) && $(MAKE) $(MAKE_FLAGS) install
