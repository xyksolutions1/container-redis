ARG DISTRO="alpine"
ARG DISTRO_VARIANT="3.21"

FROM docker.io/tiredofit/${DISTRO}:${DISTRO_VARIANT}
LABEL maintainer="Dave Conroy (github.com/tiredofit)"

ARG REDIS_VERSION

ENV REDIS_VERSION=${REDIS_VERSION:-"8.0.2"} \
    CONTAINER_ENABLE_MESSAGING=FALSE \
    IMAGE_NAME="tiredofit/redis" \
    IMAGE_REPO_URL="https://github.com/tiredofit/docker-redis/"

RUN source /assets/functions/00-container && \
    set -ex && \
    addgroup -S -g 6379 redis && \
    adduser -S -D -H -h /dev/null -s /sbin/nologin -G redis -u 6379 redis && \
    package update && \
    package upgrade && \
    package install .redis-build-deps \
				                        coreutils \
				                        gcc \
				                        linux-headers \
				                        make \
				                        musl-dev \
				                        openssl-dev \
				                        tar \
			                            && \
	\
    package install .redis-module-build-deps \
                                        autoconf \
		                                automake \
		                                bsd-compat-headers \
		                                build-base \
		                                cargo \
		                                clang \
		                                clang18-libclang \
		                                cmake \
		                                g++ \
		                                git \
		                                libffi-dev \
		                                libgcc \
		                                libtool \
		                                openssh \
		                                openssl  \
		                                py-virtualenv \
		                                py3-cryptography \
		                                py3-pip \
                                        py3-setuptools \
		                                py3-virtualenv \
		                                python3 \
		                                python3-dev \
		                                rsync \
		                                tar \
		                                unzip \
		                                which \
		                                xsimd \
		                                xz \
                                        && \
    \
    #pip install \
    #            -q \
    #            --upgrade setuptools \
    #            &&  \
    #pip install \
    #            -q \
    #            --upgrade pip \
    #            && \
    PIP_BREAK_SYSTEM_PACKAGES=1 pip install \
                                            -q \
                                                addict \
                                                jinja2 \
                                                ramp-packer \
                                                toml \
                                                && \
	clone_git_repo https://github.com/redis/redis "${REDIS_VERSION}" && \
	\
	grep -E '^ *createBoolConfig[(]"protected-mode",.*, *1 *,.*[)],$' src/config.c && \
	sed -ri 's!^( *createBoolConfig[(]"protected-mode",.*, *)1( *,.*[)],)$!\10\2!' src/config.c && \
	grep -E '^ *createBoolConfig[(]"protected-mode",.*, *0 *,.*[)],$' src/config.c && \
    \
    gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" && \
	extraJemallocConfigureFlags="--build=$gnuArch" && \
	dpkgArch="$(dpkg --print-architecture)" && \
	case "${dpkgArch##*-}" in \
		amd64 ) extraJemallocConfigureFlags="$extraJemallocConfigureFlags --with-lg-page=12" ;; \
		*) extraJemallocConfigureFlags="$extraJemallocConfigureFlags --with-lg-page=16" ;; \
	esac ; \
	extraJemallocConfigureFlags="$extraJemallocConfigureFlags --with-lg-hugepage=21"; \
	grep -F 'cd jemalloc && ./configure ' /usr/src/redis/deps/Makefile; \
	sed -ri 's!cd jemalloc && ./configure !&'"$extraJemallocConfigureFlags"' !' /usr/src/redis/deps/Makefile; \
	grep -F "cd jemalloc && ./configure $extraJemallocConfigureFlags " /usr/src/redis/deps/Makefile; \
    export \
            BUILD_TLS=yes \
            BUILD_WITH_MODULES=yes \
            INSTALL_RUST_TOOLCHAIN=yes \
            DISABLE_WERRORS=yes \
            && \
    make -C /usr/src/redis/modules/redisjson get_source; \
    sed -i 's/^RUST_FLAGS=$/RUST_FLAGS += -C target-feature=-crt-static/' /usr/src/redis/modules/redisjson/src/Makefile ; \
    grep -E 'RUST_FLAGS' /usr/src/redis/modules/redisjson/src/Makefile; \
    make -j "$(nproc)" all && \
	make install && \
	\
	serverMd5="$(md5sum /usr/local/bin/redis-server | cut -d' ' -f1)"; export serverMd5 && \
	find /usr/local/bin/redis* -maxdepth 0 \
		-type f -not -name redis-server \
		-exec sh -eux -c ' \
			md5="$(md5sum "$1" | cut -d" " -f1)"; \
			test "$md5" = "$serverMd5"; \
		' -- '{}' ';' \
		-exec ln -svfT 'redis-server' '{}' ';' \
		&& \
	\
    make -C /usr/src/redis distclean && \
    runDeps="$( \
	scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
		| tr ',' '\n' \
		| sort -u \
		| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )" && \
    package install .redis-rundeps \
                    su-exec \
                    $runDeps \
                    && \
	package remove \
                    .redis-build-deps \
                    .redis-module-build-deps \
                    && \
	rm -rf /usr/src/* && \
    package cleanup && \
    \
    mkdir -p /data && \
    chown redis:redis /data

EXPOSE 6379

COPY install /
