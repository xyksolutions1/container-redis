# nfrastack/container-redis

## About

This repository will build a container for [Redis](https://redis.io), an in-memory key value database.

## Maintainer

- [Nfrastack](https://www.nfrastack.com)


## Table of Contents

- [About](#about)
- [Maintainer](#maintainer)
- [Installation](#installation)
  - [Prebuilt Images](#prebuilt-images)
  - [Quick Start](#quick-start)
  - [Persistent Storage](#persistent-storage)
- [Configuration](#configuration)
  - [Environment Variables](#environment-variables)
    - [Base Images used](#base-images-used)
    - [Core Configuration](#core-configuration)
  - [Users and Groups](#users-and-groups)
  - [Networking](#networking)
- [Maintenance](#maintenance)
  - [Shell Access](#shell-access)
- [Support & Maintenance](#support--maintenance)
- [License](#license)

## Installation

### Prebuilt Images
Feature limited builds of the image are available on the [Github Container Registry](https://github.com/nfrastack/container-redis/pkgs/container/container-redis) and [Docker Hub](https://hub.docker.com/r/nfrastack/redis).

To unlock advanced features, one must provide a code to be able to change specific environment variables from defaults. Support the development to gain access to a code.

To get access to the image use your container orchestrator to pull from the following locations:

```
ghcr.io/nfrastack/container-redis:<branch>-(image_tag)
docker.io/nfrastack/redis:<branch>-(image_tag)
```

Image tag syntax is:

`<image>:<optional tag>`

Example:

`ghcr.io/nfrastack/container-redis:8-latest` or

`ghcr.io/nfrastack/container-redis:8-1.0` or

* `latest` will be the most recent commit
* Branch refers to the git branch you are working with and relates to the Redis main versiion.
* An otpional `tag` may exist that matches the [CHANGELOG](CHANGELOG.md) - These are the safest.
* If there are multiple distribution variations it may include a version - see the registry for availability.

Have a look at the container registries and see what tags are available.

#### Multi-Architecture Support

Images are built for `amd64` by default, with optional support for `arm64` and other architectures.

### Quick Start

* The quickest way to get started is using [docker-compose](https://docs.docker.com/compose/). See the examples folder for a working [compose.yml](examples/compose.yml) that can be modified for your use.

* Map [persistent storage](#persistent-storage) for access to configuration and data files for backup.
* Set various [environment variables](#environment-variables) to understand the capabilities of this image.

### Persistent Storage

The following directories are used for configuration and can be mapped for persistent storage.

| Directory        | Description            |
| ---------------- | ---------------------- |
| `/data`          | (optional) Data files  |
| `/logs`          | (optional) Log Files   |
| `/var/run/redis` | (optional) Socket path |

### Environment Variables

#### Base Images used

This image relies on a customized base image in order to work.
Be sure to view the following repositories to understand all the customizable options:

| Image                                                   | Description |
| ------------------------------------------------------- | ----------- |
| [OS Base](https://github.com/nfrastack/container-base/) | Base Image  |

Below is the complete list of available options that can be used to customize your installation.

* Variables showing an 'x' under the `Advanced` column can only be set if the containers advanced functionality is enabled.

#### Core Configuration

| Parameter             | Description                                           | Default           | `_FILE` |
| --------------------- | ----------------------------------------------------- | ----------------- | ------- |
| `REDIS_USER`          | What username to run as and to own folder permissions | `redis`           |         |
| `REDIS_GROUP`         | What group to set folder permissions as               | `redis`           |         |
| `LOG_TYPE`            | Choose `none` `file` `console`                        | `none`            |         |
| `LOG_PATH`            | Path for storing log files                            | `/logs/`          |         |
| `LOG_LEVEL`           | Log level                                             | `notice`          |         |
| `ENABLE_PERSISTENCE`  | Enable Data Persistence                               | `FALSE`           |         |
| `DATA_PATH`           | Path for storing persistence files                    | `/data/`          |         |
| `REDIS_PORT`          | Listening Port                                        | `6379`            |         |
| `REDIS_PASS`          | (optional) Require password to connect                |                   | x       |
| `ENABLE_SOCKET`       | Enable creating Redis Socket                          | `FALSE`           |         |
| `SOCKET_PATH`         | Path for Redis Socket                                 | `/var/run/redis/` |         |
| `SOCKET_NAME`         | Socket name `redis.sock`                              |                   |         |
| `SOCKET_PERMISSIONS`  | Socket permissions                                    | `777`             |         |
| `ZABBIX_SESSION_NAME` | (optional) Replace with Zabbix Session Name in WebUI  | `Redis1`          |         |

## Users and Groups

| Type  | Name    | ID   |
| ----- | ------- | ---- |
| User  | `redis` | 6379 |
| Group | `redis` | 6379 |

### Networking

| Port   | Protocol | Description  |
| ------ | -------- | ------------ |
| `6379` | tcp      | Redis Daemon |

* * *

## Maintenance

### Shell Access

For debugging and maintenance, `bash` and `sh` are available in the container.

## Support & Maintenance

- For community help, tips, and community discussions, visit the [Discussions board](/discussions).
- For personalized support or a support agreement, see [Nfrastack Support](https://nfrastack.com/).
- To report bugs, submit a [Bug Report](issues/new). Usage questions will be closed as not-a-bug.
- Feature requests are welcome, but not guaranteed. For prioritized development, consider a support agreement.
- Updates are best-effort, with priority given to active production use and support agreements.

## References

* https://redis.org/

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
