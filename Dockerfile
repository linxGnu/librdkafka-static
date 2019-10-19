FROM centos:centos7

# install go
ENV GOLANG_PACKAGE go1.13.3.linux-amd64.tar.gz

RUN yum -y update && \
    yum -y install gcc gcc-c++ git wget pkg-config yum-utils && \
    wget https://dl.google.com/go/${GOLANG_PACKAGE} && \
    tar -C /usr/local -xzf ${GOLANG_PACKAGE} && rm ${GOLANG_PACKAGE} && \
    yum remove `package-cleanup --leaves` && yum clean all && rm -rf /var/cache/yum

ENV GOROOT /usr/local/go
ENV GOPATH /go
ENV PATH $PATH:$GOROOT/bin:$GOPATH/bin

RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"

# build librdkafka statically
COPY Makefile /tmp/
RUN yum -y update && yum -y install make automake libtool which && \
    pushd /tmp && make && popd && rm -rf /tmp/* && \
    yum remove -y make automake libtool which && \
    yum remove `package-cleanup --leaves` && yum clean all && rm -rf /var/cache/yum

# setup pkg-config path
ENV PKG_CONFIG_PATH /usr/local/lib/pkgconfig
