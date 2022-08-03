# Yocto for Rock 3A
Build yocto for Rock 3A Board

## Build:
### Requires:
- Host need to support `docker` and `docker-compose` to build

### Prepare:
- Create the download mirror directory to store the downloaded packages
    ```bash
    mkdir -p /home/workspace/yocto_dl
    ```
    **Note**: you maybe change `/home/workspace/yocto_dl` to your directory on your host to store packages

- Set up environment for docker build
    ```bash
    ./create_docker_env.sh -d /home/workspace/yocto_dl

    repo init .
    
    repo sync
    ```

- Build docker image and run it to make container to build yocto
    ```bash
    docker-compose build

    docker-compose run rockpi3-build
    ```
### Build image
- We use the radxa-minimal-image from meta-radxa to verify
- Excute bitbake command in docker container prepared above
    ```bash
    bitbake radxa-minimal-image
    ```
- The build process will take your time, please keep your host always on when building image.