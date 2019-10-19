DEST=/usr/local
DEST_LIB=${DEST}/lib
DEST_INCLUDE=${DEST}/include

MAKE_FLAGS = -j16
CFLAGS += ${EXTRA_CFLAGS}

# Dependencies and Rocksdb
LZ4_COMMIT = e8baeca51ef2003d6c9ec21c32f1563fef1065b9
ZLIB_COMMIT = cacf7f1d4e3d44d871b605da3b647f07d718623f
ZSTD_COMMIT = 8b6d96827c24dd09109830272f413254833317d9
OPENSSL_COMMIT = 894da2fb7ed5d314ee5c2fc9fd2d9b8b74111596
SASL_COMMIT = 0189425cc210555c36383293c468df5da73acc48
RDKAFKA_COMMIT = 7aa9b3964f7b63aa355fb7ff3bfc44e39eac7195

SASL_OPTS = --enable-static=yes --enable-shared=no --prefix=$(DEST) --with-pic

default: zlib lz4 zstd sasl openssl rdkafka

.PHONY: zlib
zlib:
	git clone https://github.com/madler/zlib.git
	cd zlib && git checkout $(ZLIB_COMMIT)
	cd zlib && CFLAGS='-fPIC -O2 ${EXTRA_CFLAGS}' ./configure --static && \
	$(MAKE) clean && $(MAKE) $(MAKE_FLAGS) all
	cp zlib/libz.a $(DEST_LIB)/
	cp zlib/*.h $(DEST_INCLUDE)/

.PHONY: lz4
lz4:
	git clone https://github.com/lz4/lz4.git
	cd lz4 && git checkout $(LZ4_COMMIT)
	cd lz4 && $(MAKE) clean && $(MAKE) $(MAKE_FLAGS) CFLAGS='-fPIC -O2 ${EXTRA_CFLAGS}' lz4 lz4-release
	cp lz4/lib/liblz4.a $(DEST_LIB)/
	cp lz4/lib/*.h $(DEST_INCLUDE)/

.PHONY: zstd
zstd:
	git clone https://github.com/facebook/zstd.git
	cd zstd && git checkout $(ZSTD_COMMIT)
	cd zstd/lib && $(MAKE) clean && DESTDIR=. PREFIX= $(MAKE) $(MAKE_FLAGS) CFLAGS='-fPIC -O2 ${EXTRA_CFLAGS}' all install
	cp zstd/lib/libzstd.a $(DEST_LIB)/
	cp zstd/lib/include/*.h $(DEST_INCLUDE)/

.PHONY: sasl
sasl:
	git clone https://github.com/cyrusimap/cyrus-sasl.git && mv cyrus-sasl sasl
	cd sasl && git checkout $(SASL_COMMIT)
	cd sasl && sh autogen.sh $(SASL_OPTS) && ./configure $(SASL_OPTS) && $(MAKE) $(MAKE_FLAGS) install

.PHONY: openssl
openssl:
	git clone https://github.com/openssl/openssl.git
	cd openssl && git checkout $(OPENSSL_COMMIT)
	cd openssl && \
	./config no-dso no-shared no-tests zlib --release \
	CFLAGS='-fPIC -O2 -Wl,--allow-multiple-definition ${EXTRA_CFLAGS}' --prefix=$(DEST) && \
	$(MAKE) $(MAKE_FLAGS) && $(MAKE) $(MAKE_FLAGS) install

.PHONY: rdkafka
rdkafka:
	git clone https://github.com/edenhill/librdkafka.git && mv librdkafka rdkafka
	cd rdkafka && git checkout $(RDKAFKA_COMMIT)
	cd rdkafka && $(MAKE) clean && mkdir build && \
	./configure --prefix=$(DEST) \
	--CPPFLAGS="-fPIC -O2 -Wl,--allow-multiple-definition -Wl,-rpath" \
	--disable-shared --no-cache --enable-static --enable-zstd --enable-sasl \
	--enable-ssl --enable-gssapi --enable-lz4-ext --enable-c11threads --disable-debug-symbols
	cd rdkafka && \
	$(MAKE) $(MAKE_FLAGS) && $(MAKE) $(MAKE_FLAGS) install
