# grit starter installation guides

This document provides step-by-step instructions for installing and running the [grit Scientific Data Management System](https://github.com/grit42/grit) in different environments.

* [Local Installation (Windows)](#local-installation-windows)
* [Local Installation (Mac)](#local-installation-mac)
* [Local Installation (Linux)](#local-installation-linux)
* [Cloud Server Installation](#cloud-server-installation)
* [Mail Service Configuration](#mail-service-configuration)
* [Maintaining the App](#maintaining-the-app)
    * [Backup the Database](#backup-the-database)
    * [Restore the Latest Backup](#restore-the-latest-backup)
    * [Upgrading to a New Version](#upgrading-to-a-new-version)
    * [Upgrading from Previous Sample Docker Compose](#upgrading-from-previous-sample-docker-compose)
---

## Local Installation (Windows)

### Requirements

- [Docker Desktop](https://docs.docker.com/get-started/get-docker/)
- Make sure Docker Desktop is running before continuing.

### Steps

1. **Download the project files**

   Either clone the repository:

   ```powershell
   git clone https://github.com/grit42/grit-starter.git
   cd grit-starter
   ```

   Or download and unzip:
   [Download ZIP](https://github.com/grit42/grit-starter/archive/refs/heads/main.zip)

2. **Prepare the environment file**

   In the project folder, copy `.env.template` to `.env`:

   ```powershell
   copy .env.template .env
   ```

   If using File Explorer, note that `.env.template` might be hidden.

3. **Start grit**

   In the project folder, run:

   ```powershell
   docker compose up
   ```

   The first run may take several minutes as images are downloaded.

4. **Activate the admin account**

   Open [http://localhost:3000/app/core/activate/admin](http://localhost:3000/app/core/activate/admin) and set a password for the `admin` user.

---

## Local Installation (Mac)

### Requirements

- [Docker Desktop](https://docs.docker.com/get-started/get-docker/)
- Make sure Docker Desktop is running before continuing.

### Steps

1. **Download the project files**

   Either clone the repository:

   ```sh
   git clone https://github.com/grit42/grit-starter.git
   cd grit-starter
   ```

   Or download and unzip:
   [Download ZIP](https://github.com/grit42/grit-starter/archive/refs/heads/main.zip)

2. **Prepare the environment file**

   In the project folder, copy `.env.template` to `.env`:

   ```sh
   cp .env.template .env
   ```

   If using Finder, make sure hidden files are visible.

3. **Start grit**

   In the project folder, run:

   ```sh
   docker compose up
   ```

   The first run may take several minutes as images are downloaded.

4. **Activate the admin account**

   Open [http://localhost:3000/app/core/activate/admin](http://localhost:3000/app/core/activate/admin) and set a password for the `admin` user.

---

## Local Installation (Linux)

### Requirements

- [Docker](https://docs.docker.com/get-started/get-docker/)

- Ensure the Docker daemon is running:

  ```sh
  systemctl status docker
  ```

- If the Docker daemon is not running, start it if it's not

  ```sh
  systemctl start docker
  ```

### Steps

1. **Download the project files**

   Clone the repository:

   ```sh
   git clone https://github.com/grit42/grit-starter.git
   cd grit-starter
   ```

   Or download and unzip:
   [Download ZIP](https://github.com/grit42/grit-starter/archive/refs/heads/main.zip)

2. **Prepare the environment file**

   In the project folder, copy `.env.template` to `.env`:

   ```sh
   cp .env.template .env
   ```

   If using a file explorer, make sure hidden files are visible.

3. **Start grit**

   In the project folder, run:

   ```sh
   docker compose up
   ```

4. **Activate the admin account**

   Open [http://localhost:3000/app/core/activate/admin](http://localhost:3000/app/core/activate/admin) and set a password for the `admin` user.

---

## Cloud Server Installation

### Requirements

- A cloud server with at least:

  - 2 vCPUs @ 3 GHz
  - 4 GB RAM
  - 40 GB storage

- Examples: Hetzner CPX21, AWS EC2 t3.medium, DigitalOcean Droplet.

- Docker installed.

- Domain name and SSL certificate recommended for production use.

### Steps

1. **Prepare your server**

   - Connect via SSH:

     ```sh
     ssh user@your-server-ip
     ```

   - Ensure Docker is installed, and the Docker daemon is running:

     ```sh
     docker --version
     systemctl status docker
     ```

2. **Download the project files**

   ```sh
   git clone https://github.com/grit42/grit-starter.git
   cd grit-starter
   ```

   Or download and extract the ZIP file.

   ```sh
   # Using curl
   curl -LO https://github.com/grit42/grit-starter/archive/refs/heads/main.zip

   # Or using wget
   wget https://github.com/grit42/grit-starter/archive/refs/heads/main.zip
   ```

3. **Prepare the environment file**

   ```sh
   cp .env.template .env
   ```

   Edit `.env` to set `GRIT_SERVER_URL` to your server’s domain:

   ```
   GRIT_SERVER_URL=https://grit.example.com
   ```

4. **Start grit**

   ```sh
   docker compose up -d
   ```

   The `-d` flag runs containers in the background.

5. **Activate the admin account**

   Visit:

   ```
   https://grit.example.com/app/core/activate/admin
   ```

   Set a password for the `admin` user.

---

## Mail Service Configuration

Some grit features (user management, password reset, two-factor authentication) require email.

In `.env`, uncomment and set the following variables:

```sh
SMTP_SERVER=smtp.example.com
SMTP_PORT=587
SMTP_USER=user@example.com
SMTP_TOKEN=your_password_or_token
GRIT_SERVER_URL=https://yourdomain.com
```

---

## Maintaining the App

### Backup the Database

Run:

```sh
docker compose run --rm backup
```

### Restore the Latest Backup

Run:

```sh
docker compose run --rm restore
```

### Upgrading to a New Version

Check [GitHub Discussions](https://github.com/grit42/grit/discussions/categories/announcements) for release notes.

Upgrade with:

```sh
docker compose pull app
docker compose up --no-deps --force-recreate app
```

### Upgrading from Previous Sample Docker Compose

1. Clone or download this repo.

2. Copy `.env.template` to `.env`.

3. Ensure `.env` values match the old configuration.

4. Start the new database service:

   ```sh
   docker compose up -d db
   ```

5. Copy data from the old volume (example for Linux):

   ```sh
   docker run --rm \
       -v ./postgres-data:/from \
       -v grit_postgres_data:/to \
       alpine \
       sh -c "cd /from && tar cf - . | tar xf - -C /to"
   ```

6. Fix file permissions:

   ```sh
   docker run --rm \
     -v grit_postgres_data:/data \
     alpine \
     chown -R 999:999 /data
   ```
