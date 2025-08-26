-- file: ./data/initdb.d/init.sql

-- This script will be executed on the first run of the MariaDB container.
-- It creates the necessary databases with the correct character set
-- and grants privileges to the 'sync' user.

-- Create the databases with UTF8MB4 support for full Unicode compatibility
CREATE DATABASE IF NOT EXISTS `syncstorage_rs` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS `tokenserver_rs` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- The 'sync' user is created by the container's environment variables.
-- We grant it privileges on the new databases, allowing connection from any host ('%').
GRANT ALL PRIVILEGES ON `syncstorage_rs`.* TO 'sync'@'%';
GRANT ALL PRIVILEGES ON `tokenserver_rs`.* TO 'sync'@'%';

-- Apply the privilege changes immediately.
FLUSH PRIVILEGES;
