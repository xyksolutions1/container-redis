ARG BASE_IMAGE

FROM ${BASE_IMAGE}

LABEL \
        org.opencontainers.image.title="Redis" \
        org.opencontainers.image.description="In memory key value database" \
        org.opencontainers.image.url="https://hub.docker.com/r/nfrastack/redis" \
        org.opencontainers.image.documentation="https://github.com/nfrastack/container-redis/blob/main/README.md" \
        org.opencontainers.image.source="https://github.com/nfrastack/container-redis.git" \
        org.opencontainers.image.authors="Nfrastack <code@nfrastack.com>" \
        org.opencontainers.image.vendor="Nfrastack <https://www.nfrastack.com>" \
        org.opencontainers.image.licenses="MIT"

ARG \
    REDIS_VERSION="7.4.6" \
    REDIS_REPO_URL="https://github.com/redis/redis"

COPY CHANGELOG.md /usr/src/container/CHANGELOG.md
COPY LICENSE /usr/src/container/LICENSE
COPY README.md /usr/src/container/README.md

ENV \
    IMAGE_NAME="nfrastack/redis" \
    IMAGE_REPO_URL="https://github.com/nfrastack/container-redis/"

RUN echo "" && \
    REDIS_BUILD_DEPS_ALPINE=" \
                                coreutils \
                                gcc \
                                linux-headers \
                                make \
                                musl-dev \
                                openssl-dev \
                                tar \
                            " \
                            && \
    \
    REDIS_RUN_DEPS_ALPINE=" \
                          " \
                          && \
    \
    source /container/base/functions/container/build && \
    container_build_log image && \
    create_user redis 6379 redis 6379 /dev/null && \
    package update && \
    package upgrade && \
    package install \
                        REDIS_BUILD_DEPS \
                        REDIS_RUN_DEPS \
                        && \
	clone_git_repo https://github.com/redis/redis "${REDIS_VERSION}" && \
	\
    case "$(cotnainer_distro arch)" in \
        x86_64) \
            build_arch="x86_64-linux-gnu" ; \
            lg_page="--with-lg-page=12" ;; \
        aarch64) \
            build_arch="aarch64-linux-gnu" ; \
            lg_page="--with-lg-page=16" ;; \
        *) : ;; \
    esac; \
    \
    jemalloc_flags="--build ${build_arch} ${lg_page} --with-lg-hugepage=21" && \
    grep -E '^ *createBoolConfig[(]"protected-mode",.*, *1 *,.*[)],$' src/config.c && \
	sed -ri 's!^( *createBoolConfig[(]"protected-mode",.*, *)1( *,.*[)],)$!\10\2!' src/config.c && \
	grep -E '^ *createBoolConfig[(]"protected-mode",.*, *0 *,.*[)],$' src/config.c && \
	\
	export BUILD_TLS=yes && \
    grep -F 'cd jemalloc && ./configure ' /usr/src/redis/deps/Makefile; \
	sed -ri 's!cd jemalloc && ./configure !&'"$jemalloc_flags"' !' /usr/src/redis/deps/Makefile; \
	grep -F "cd jemalloc && ./configure $jemalloc_flags " /usr/src/redis/deps/Makefile; \
	make -j "$(nproc)" all && \
	make install && \
	\
    runDeps="$( \
	scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
		| tr ',' '\n' \
		| sort -u \
		| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )" && \
    mkdir -p /data && \
    chown redis:redis /data && \
    container_build_log add "Redis" "${REDIS_VERSION}" "${REDIS_REPO_URL}" && \
    package install \
                        REDIS_RUN_DEPS \
                        $runDeps \
                        && \
	package remove \
                        REDIS_BUILD_DEPS \
                        && \
    package cleanup

EXPOSE 6379

COPY rootfs /
