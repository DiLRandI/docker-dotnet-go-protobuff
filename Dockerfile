FROM buildpack-deps:buster-scm

# Install .NET CLI dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libc6 \
        libgcc1 \
        libgssapi-krb5-2 \
        libicu63 \
        libssl1.1 \
        libstdc++6 \
        zlib1g \
    && rm -rf /var/lib/apt/lists/*

# Install .NET Core SDK
ENV DOTNET_SDK_VERSION 3.0.100

RUN curl -SL --output dotnet.tar.gz https://dotnetcli.blob.core.windows.net/dotnet/Sdk/$DOTNET_SDK_VERSION/dotnet-sdk-$DOTNET_SDK_VERSION-linux-x64.tar.gz \
    && dotnet_sha512='766da31f9a0bcfbf0f12c91ea68354eb509ac2111879d55b656f19299c6ea1c005d31460dac7c2a4ef82b3edfea30232c82ba301fb52c0ff268d3e3a1b73d8f7' \
    && echo "$dotnet_sha512 dotnet.tar.gz" | sha512sum -c - \
    && mkdir -p /usr/share/dotnet \
    && tar -zxf dotnet.tar.gz -C /usr/share/dotnet \
    && rm dotnet.tar.gz \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet

# Enable detection of running in a container
ENV DOTNET_RUNNING_IN_CONTAINER=true \
    # Enable correct mode for dotnet watch (only mode supported in a container)
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    # Skip extraction of XML docs - generally not useful within an image/container - helps performance
    NUGET_XMLDOC_MODE=skip

# Trigger first run experience by running arbitrary cmd
RUN dotnet help

# Install PowerShell global tool
ENV POWERSHELL_VERSION=7.0.0-preview.4 \
    POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-DotnetCoreSDK-Debian-10

RUN curl -SL --output PowerShell.Linux.x64.$POWERSHELL_VERSION.nupkg https://pwshtool.blob.core.windows.net/tool/$POWERSHELL_VERSION/PowerShell.Linux.x64.$POWERSHELL_VERSION.nupkg \
    && powershell_sha512='0fb0167e13560371bffec38a4a87bf39377fa1a5cc39b3a078ddec8803212bede73e5821861036ba5c345bd55c74703134c9b55c49385f87dae9e2de9239f5d9' \
    && echo "$powershell_sha512  PowerShell.Linux.x64.$POWERSHELL_VERSION.nupkg" | sha512sum -c - \
    && mkdir -p /usr/share/powershell \
    && dotnet tool install --add-source / --tool-path /usr/share/powershell --version $POWERSHELL_VERSION PowerShell.Linux.x64 \
    && rm PowerShell.Linux.x64.$POWERSHELL_VERSION.nupkg \
    && ln -s /usr/share/powershell/pwsh /usr/bin/pwsh \
    # To reduce image size, remove the copy nupkg that nuget keeps.
    && find /usr/share/powershell -print | grep -i '.*[.]nupkg$' | xargs rm

# gcc for cgo
RUN apt-get update && apt-get install -y --no-install-recommends \
		g++ \
		gcc \
		libc6-dev \
		make \
		pkg-config \
	&& rm -rf /var/lib/apt/lists/*

ENV GOLANG_VERSION 1.13.1

RUN set -eux; \
	\
# this "case" statement is generated via "update.sh"
	dpkgArch="$(dpkg --print-architecture)"; \
	case "${dpkgArch##*-}" in \
		amd64) goRelArch='linux-amd64'; goRelSha256='94f874037b82ea5353f4061e543681a0e79657f787437974214629af8407d124' ;; \
		armhf) goRelArch='linux-armv6l'; goRelSha256='7c75d4002321ea4a066dfe13f6dd5168076e9a231317c5afd55e78b86f478e37' ;; \
		arm64) goRelArch='linux-arm64'; goRelSha256='8af8787b7c2a3c0eb3f20f872577fcb6c36098bf725c59c4923921443084c807' ;; \
		i386) goRelArch='linux-386'; goRelSha256='4bf7a961fda7ad892b8824002036de8c0f290df05df2e8f11252d1f8c77dcd8f' ;; \
		ppc64el) goRelArch='linux-ppc64le'; goRelSha256='72422c68dbed013ee321a05dbb97d9c8d6b2c75f347de707138c2c748fc4aceb' ;; \
		s390x) goRelArch='linux-s390x'; goRelSha256='5f0859ae1037ad7af6cdb6d16f638de908fd9de044d463eeab92b9578d4c7c75' ;; \
		*) goRelArch='src'; goRelSha256='81f154e69544b9fa92b1475ff5f11e64270260d46e7e36c34aafc8bc96209358'; \
			echo >&2; echo >&2 "warning: current architecture ($dpkgArch) does not have a corresponding Go binary release; will be building from source"; echo >&2 ;; \
	esac; \
	\
	url="https://golang.org/dl/go${GOLANG_VERSION}.${goRelArch}.tar.gz"; \
	wget -O go.tgz "$url"; \
	echo "${goRelSha256} *go.tgz" | sha256sum -c -; \
	tar -C /usr/local -xzf go.tgz; \
	rm go.tgz; \
	\
	if [ "$goRelArch" = 'src' ]; then \
		echo >&2; \
		echo >&2 'error: UNIMPLEMENTED'; \
		echo >&2 'TODO install golang-any from jessie-backports for GOROOT_BOOTSTRAP (and uninstall after build)'; \
		echo >&2; \
		exit 1; \
	fi; \
	\
	export PATH="/usr/local/go/bin:$PATH"; \
	go version

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"
WORKDIR /tmp
RUN wget https://github.com/protocolbuffers/protobuf/releases/download/v3.10.0/protobuf-all-3.10.0.tar.gz
RUN apt-get update && apt-get install -y --no-install-recommends autoconf automake libtool curl make g++ unzip
RUN mkdir -p /usr/local/protobuf; \
    tar zxf protobuf-all-3.10.0.tar.gz -C /usr/local/protobuf; \
    cd /usr/local/protobuf/protobuf-3.10.0; \
    ./configure; \
    make; \
    make check; \
    make install; \
    ldconfig; \
    protoc;
RUN rm -rf /tmp/* /usr/local/protobuf

WORKDIR /

RUN dotnet --info && go version && protoc --version