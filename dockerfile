FROM alpine:latest
WORKDIR /tmp
# download go lang 
RUN apk update; \
    apk upgrade; \
    apk add --no-cache --verbose bash gcc musl-dev openssl go autoconf automake libtool curl make g++ unzip git;
RUN wget https://dl.google.com/go/go1.13.1.linux-amd64.tar.gz
RUN tar -C /usr/local -xzf go1.13.1.linux-amd64.tar.gz; \
    cd /usr/local/go/src/; \
    ./make.bash; \
    rm -rf /usr/local/go/pkg/bootstrap /usr/local/go/pkg/obj; \
    export PATH="/usr/local/go/bin:$PATH"; \
    go version;
ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"

WORKDIR /tmp
# download dont net sdk 3.0.1
RUN wget https://download.visualstudio.microsoft.com/download/pr/f9dc42c0-9b15-44e6-9d9b-ef341fdbf1a7/78b16d311f1c4366fed65e69eaece49d/dotnet-sdk-3.0.100-linux-musl-x64.tar.gz
RUN apk update; \
    apk upgrade; \
    apk add --no-cache --verbose bash gcc musl-dev openssl go autoconf automake libtool curl make g++ unzip git;
RUN mkdir -p /usr/local/dotnet; \
    tar zxf dotnet-sdk-3.0.100-linux-musl-x64.tar.gz -C /usr/local/dotnet; \
    export DOTNET_ROOT=/usr/local/dotnet; \
    export PATH=/usr/local/dotnet:$PATH;

WORKDIR /tmp
# Protocolbuffer
RUN wget https://github.com/protocolbuffers/protobuf/releases/download/v3.10.0/protobuf-all-3.10.0.tar.gz
RUN apk update; \
    apk upgrade; \
    apk add --no-cache --verbose bash gcc musl-dev openssl go autoconf automake libtool curl make g++ unzip git;
RUN mkdir -p /usr/local/protobuf; \
    tar zxf protobuf-all-3.10.0.tar.gz -C /usr/local/protobuf; \
    cd /usr/local/protobuf/protobuf-3.10.0; \
    ./configure; \
    make; \
    make check; \
    make install; \
    ldconfig; \
    protoc;

RUN rm -rf /tmp/*
RUN rm -rf var/cache/apk/*
WORKDIR /
#    export PATH=$PATH:/usr/local/protobuf; \