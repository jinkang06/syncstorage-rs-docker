# SyncStorage-RS-Docker (fixed and enhanced version)

This warehouse is a Fork of [Dan-r/syncstorage-RS-docker] (https://github.com/Dan-r/syncstorage-RS-docker). The original project provided a good starting point for building the Firefox Sync server, but there were some challenges in the actual deployment process, such as long construction time, large image size, incompatible environment and unreliable database initialization.

This Fork warehouse contains a series of key fixes and architecture improvements, aiming at providing a * * out-of-the-box, stable, reliable and easy to maintain * * deployment scheme of Firefox synchronization server.

# # Core improvement

Compared with the original warehouse, this warehouse has the following enhancements:

1. ** Multi-stage Docker build * *
* completely rewritten ` app/Dockerfile' and adopted multi-stage construction strategy.
* * * Results * *: The final image size of' syncserver' was greatly reduced from **~2GB+** of the original version to **~500MB**, at the same time, it was more efficient to build cache and the secondary construction speed was faster.

2. ** Unified construction and operation environment * *
* Building image (`Rust: 1.82-Bookworm`) and running image (`Debian: Bookworm`) are based on debian:bookworm system.
* * * Result * *: The problem of conflict or missing of dynamic library versions such as `glibc', `libpython' and `libcurl' caused by environment mismatch was fundamentally solved.

3. ** Reliable database initialization * *
* Changing MariaDB image from linuxserver/mariadb DB' to official `Maria DB: 10.6', its initialization process is more standard and transparent.
* A' healthcheck' mechanism was added to MariaDB in' docker-compose.yaml' to ensure that' syncserver' was started only after the database was completely ready, thus eliminating the timing problem.
* Using init.sql script to explicitly create database and authorization, which solved the possible permission problems in the original configuration.

4. ** Robust startup script and configuration * *
* Simplify the variables in the `. env ` file and ` docker-compose.yaml' to make them clearer and easier to understand.
* The script app/entrypoint.sh was optimized to make its responsibilities more single, and the syntax bug of the startup command was fixed.

5. ** Enhanced security * *
* Added `. gitignore file, and ignored `. env` file by default to prevent sensitive information containing passwords and keys from being accidentally uploaded to the version library.

# # Quick Start

Please follow these steps to deploy your own Firefox Sync server.

### 1. Clone this warehouse

```bash
git clone [https://github.com/jinkang06/syncstorage-rs-docker.git](https://github.com/jinkang06/syncstorage-rs-docker.git)
cd syncstorage-rs-docker

