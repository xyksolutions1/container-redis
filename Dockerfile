ARG DISTRO="alpine"
ARG DISTRO_VARIANT="3.21"

FROM docker.io/tiredofit/${DISTRO}:${DISTRO_VARIANT}
LABEL maintainer="Dave Conroy (github.com/tiredofit)"

ARG REDIS_VERSION

ENV REDIS_VERSION=${REDIS_VERSION:-"7.4.5"} \
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
	clone_git_repo https://github.com/redis/redis "${REDIS_VERSION}" && \
	\
	grep -E '^ *createBoolConfig[(]"protected-mode",.*, *1 *,.*[)],$' src/config.c && \
	sed -ri 's!^( *createBoolConfig[(]"protected-mode",.*, *)1( *,.*[)],)$!\10\2!' src/config.c && \
	grep -E '^ *createBoolConfig[(]"protected-mode",.*, *0 *,.*[)],$' src/config.c && \
	\
    case "$(apk --print-arch)" in \
        x86_64) \
            build_arch="x86_64-linux-gnu" ; \
            lg_page="--with-lg-page=12" ;; \
        aarch64) \
            build_arch="aarch64-linux-gnu" ; \
            lg_page="--with-lg-page=16" ;; \
        *) : ;; \
    esac; \
    jemalloc_flags="--build ${build_arch} ${lg_page} --with-lg-hugepage=21"  && \
	export BUILD_TLS=yes && \
    grep -F 'cd jemalloc && ./configure ' /usr/src/redis/deps/Makefile; \
	sed -ri 's!cd jemalloc && ./configure !&'"$jemalloc_flags"' !' /usr/src/redis/deps/Makefile; \
	grep -F "cd jemalloc && ./configure $jemalloc_flags " /usr/src/redis/deps/Makefile; \
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
	package remove .redis-build-deps && \
	rm -rf /usr/src/* && \
    package cleanup && \
    \
    mkdir -p /data && \
    chown redis:redis /data

EXPOSE 6379

COPY install /
