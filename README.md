# Solana Docker for Apple Silicon

Docker config for Macs running Apple Silicon, to support development on Solana

![README_Banner](.github/README_Banner.png)

## GHCR & Docker Hub Support

unfortunately the bozos at Microsoft don't want to support ARM64 so you'll have to build the image yourself before you can use it

## Quickstart

```shell
docker build github.com/raphtlw/solana-docker-mac-m1 -t raphtlw/solana
```

<!--
    ```shell
    curl https://github.com/raphtlw/solana-docker-mac-m1/archive/refs/heads/main.tar.gz -sSLf -o solana-docker-mac-m1.tar.gz
    mkdir -p solana-docker-mac-m1
    cd solana-docker-mac-m1
    tar -xvf ../solana-docker-mac-m1.tar.gz --strip-components=1
    docker build . -t raphtlw/solana
    ```
-->

## Usage

Note, `docker run` creates a new container every time. The following commands show how you can re-use the same container.

If you'd like to use the container only once as a command, see below.

### Start the container

Create a new instance of a container running a test validator in the background

```shell
$ docker run --name solana -d raphtlw/solana solana-test-validator
```

### Run a test validator

You can start a test validator inside the container

```shell
$ docker exec -it raphtlw/solana solana-test-validator
```

### Drop into a shell

```shell
$ docker exec -it raphtlw/solana fish
```

### Short-lived container

You can quickly start a new ephemeral container and run a specific solana program inside

```shell
$ docker run --rm -it -v $PWD:/tmp raphtlw/solana <command to run>
```

You can alias it into a command for easier access:

```shell
$ alias solana="docker run --rm -it -v $PWD:/tmp raphtlw/solana"
```

Example running a solana cluster:

```shell
$ solana run-cluster
```
