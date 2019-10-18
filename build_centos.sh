#!/bin/bash

# update sys
yum update -y

# install tooling
yum install -y git wget which make gcc gcc-c++ automake libtool

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

# build rdkafka
PATH=$PATH:/opt/cmake/bin
make

# remove deps for linking
yum remove -y snappy-devel zlib-devel lz4-devel cyrus-sasl-devel openssl-devel

# remove tooling
yum remove -y make automake libtool
