#!/bin/bash

# update sys
yum update -y

# install tooling
yum install -y git wget which make gcc gcc-c++ automake libtool glibc-static libstdc++-static

# install deps for linking
yum install -y snappy-devel zlib-devel lz4-devel cyrus-sasl-devel openssl-devel

# install cmake
wget https://cmake.org/files/v3.11/cmake-3.11.4.tar.gz
tar xzf cmake-3.11.4.tar.gz
pushd cmake-3.11.4
./bootstrap --prefix=/opt/cmake --no-system-libs
make install -j8
popd
rm -rf cmake-3.11.4 cmake-3.11.4.tar.gz

# install zstd
wget https://github.com/facebook/zstd/releases/download/v1.4.3/zstd-1.4.3.tar.gz
tar xzf zstd-1.4.3.tar.gz
pushd zstd-1.4.3
make install -j8
popd
rm -rf zstd-1.4.3 zstd-1.4.3.tar.gz

# build rocksdb
PATH=$PATH:/opt/cmake/bin
make

# remove deps for linking
yum remove -y snappy-devel zlib-devel lz4-devel cyrus-sasl-devel openssl-devel

# remove tooling
yum remove -y automake libtool
