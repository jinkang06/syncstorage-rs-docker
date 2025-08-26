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
git clone https://github.com/jinkang06/syncstorage-rs-docker.git
cd syncstorage-rs-docker


### Environment Variables

The Docker Compose file makes use of environment variables. To configure them, make a copy of example.env

```bash
cp example.env .env
```

Now edit the new `.env` file to add configuration and secrets. Keep in mind the `SYNC_MASTER_SECRET` and `METRICS_HASH_SECRET` require 64 characters.

### Initial Run

```bash
docker compose up -d --build && docker compose logs -f
```

The first time you run the application, it will do a few things:

1. MariaDB container will be pulled and on first run it will load the `./data/init/init.sql` script that creates the required databases and user permissions. This will only run during the initial setup.

2. Next the Dockerfile will build the syncserver app. This is a Rust app and all of the required dependencies will be loaded into the environment, as well as cloning the Mozilla syncstorage-rs repo. This will take several minutes.

3. Once everything is compiled and configured you should see startup logs begin to appear. Subsequent runs of `docker compose up -d` will happen much faster because the build artifacts are cached. Data is persisted in the database (`./data/config`) between restarts.

### Rebuilding Everything

In the course of setting this up, you may need to tear down and rebuild your instance. To remove persisted data and artifacts, run the following.

```bash
docker compose down
docker image rm app-syncserver
docker builder prune -af
rm -rf ./data/config
```

This will delete the compiled Rust app and any cached layers, and also delete the database data.

### Firefox Setup

Once your app is running, you can configure Firefox by updating the `about:config` settings.

`identity.sync.tokenserver.uri` needs to be set to the `SYNC_URL` configured in your `.env` file followed by `/1.0/sync/1.5`. 

>Example: http://sync.example.com:8000/1.0/sync/1.5

To confirm the sync is working you can enable success logs in `about:config` also. Set `services.sync.log.appender.file.logOnSuccess` to true. Now you should see sync logs in `about:sync-log`

Syncing is usually very quick, and when a sync occurs you can see logs in `docker compose logs -f` also.

