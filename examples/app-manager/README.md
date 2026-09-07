# Run WProofreader and App-manager with Docker Compose

This folder provides a self-contained Docker Compose setup for running
WProofreader Server, App-manager (On-Prem), and MySQL on a single host. There is
no build step, and you do not need any other files from this repository.

This setup is a good fit for evaluation, demonstrations, and small installations.
For a resilient production deployment, use an architecture with regular backups,
a reverse proxy or load balancer, a managed database, and multiple App-manager
instances.

## What the stack includes

| Service | Image | What it does |
| --- | --- | --- |
| `mysql` | `mysql:8.4` | Stores two databases: `app_manager_db` for App-manager and `cloud_service` for WProofreader Server. |
| `db-manager` | `webspellchecker/db-manager` | Runs once at startup to create `cloud_service`, apply its schema and seed data, and create the `appserver` and `app_service` database users. It exits when finished. |
| `appserver` | `webspellchecker/wproofreader` | Runs WProofreader Server with its database provider enabled. |
| `app-manager` | `webspellchecker/app-manager` | Runs the App-manager web application, queue worker, and scheduler. It applies its own database migrations during startup. |

Docker Compose starts the services in the required order:

1. MySQL starts and becomes healthy.
2. db-manager provisions the WProofreader database.
3. WProofreader Server and App-manager start.

If db-manager fails, the two application services do not start. This prevents
them from running against a missing or incomplete database schema.

## Before you begin

Make sure the host has:

- Docker Engine 24 or newer with the Compose plugin. Check with
  `docker compose version`.
- A valid WProofreader license ticket.
- Enough memory for WProofreader Server. See the
  [installation requirements](https://docs.webspellchecker.com/display/WebSpellCheckerServer55x/Installation+requirements).
- Free ports `8080` and `8081` on the loopback interface, unless you plan to
  change them in `.env`.

Run all commands in this guide from the `examples/app-manager` directory.

## Configure the stack

1. Create your local environment file:

   ```bash
   cp .env.example .env
   ```

2. Generate an encryption key for App-manager:

   ```bash
   openssl rand -base64 32 | sed 's/^/base64:/'
   ```

   Copy the complete output, including the `base64:` prefix, into `APP_KEY` in
   `.env`. Keep this value safe and stable. Changing it later invalidates active
   sessions and existing invitation links.

3. Open `.env` and set the required values:

   | Variable | Purpose |
   | --- | --- |
   | `LICENSE_TICKET_ID` | Activates WProofreader Server. |
   | `MYSQL_ROOT_PASSWORD` | MySQL administrative password. |
   | `APP_MANAGER_DB_PASSWORD` | Password App-manager uses for `app_manager_db`. |
   | `SERVICE_DB_PASSWORD` | Password App-manager uses for `cloud_service`. |
   | `APPSERVER_DB_PASSWORD` | Password WProofreader Server uses for `cloud_service`. |

   Choose strong, unique database passwords before the first start. MySQL uses
   these values when it creates the data volume and does not automatically
   change existing accounts when `.env` changes later.

   Keep `.env` private. It contains credentials and must not be committed or
   shared in support bundles.

4. Review the image versions. `WPROOFREADER_VERSION` selects both the
   WProofreader Server and matching db-manager release. Normally these versions
   should remain aligned. Use `DB_MANAGER_VERSION` only when you intentionally
   need a different db-manager build.

   The example uses `webspellchecker` image repository names by default. If
   your release is distributed through a private registry such as Amazon ECR, set
   `WPROOFREADER_IMAGE`, `DB_MANAGER_IMAGE`, or `APP_MANAGER_IMAGE` to the
   repository you were given, without a tag, and authenticate with that
   registry before continuing.

5. Optional: change `APP_MANAGER_PORT`, `APPSERVER_PORT`, mail settings, or the
   public URLs. The defaults are suitable for local access.

6. Check the completed configuration for Compose errors:

   ```bash
   docker compose config --quiet
   ```

## Start the stack

Start all services in the background:

```bash
docker compose up -d
```

The first start may take several minutes while Docker downloads the images and
MySQL initializes its data directory.

Check progress, including the one-time db-manager container, with:

```bash
docker compose ps --all
```

When startup is complete:

- `mysql`, `appserver`, and `app-manager` should be running and healthy.
- `db-manager` should show `Exited (0)`. This is expected: it is a one-time job,
  not a long-running service.

The applications are available at:

- App-manager: <http://localhost:8080>
- WProofreader Server: <http://localhost:8081/wscservice/>

If you changed either port in `.env`, use the new port in these URLs.

### Create the first administrator

App-manager generates a one-time setup link during its first startup. Display it
with:

```bash
docker compose logs app-manager | grep -A1 'Setup URL'
```

Open the URL in a browser and create the first administrator account.

The setup token expires after 24 hours. If it is no longer visible in the logs,
you can read it from the container until setup is completed:

```bash
docker compose exec app-manager \
  cat storage/app/onprem-setup-token
```

### Verify WProofreader Server

Check the status endpoint:

```bash
curl 'http://localhost:8081/wscservice/api?cmd=status'
```

A successful response confirms that WProofreader Server is reachable. You can
also review its health with `docker compose ps --all` and its logs with
`docker compose logs appserver`.

## Day-to-day operations

| Task | Command |
| --- | --- |
| Show all service state and health | `docker compose ps --all` |
| Follow all logs | `docker compose logs -f` |
| Follow one service | `docker compose logs -f app-manager` |
| Stop the stack without removing containers | `docker compose stop` |
| Start stopped containers | `docker compose start` |
| Remove containers while keeping data | `docker compose down` |

> **Warning:** `docker compose down -v` permanently deletes the MySQL databases,
> App-manager storage, and WProofreader dictionaries. Use it only when you
> intentionally want to start again from an empty installation.

### App-manager operator commands

Run Artisan commands inside the App-manager container. For example, generate a
new setup token after the previous token expires:

```bash
docker compose exec app-manager \
  php artisan app:setup-token --regenerate
```

Other useful commands include:

| Command | Purpose |
| --- | --- |
| `admin:create` | Create the first administrator from the command line. |
| `user:reset-password` | Reset a user's password. |
| `onprem:reconcile-services` | Repair product activations. This also runs automatically every hour. |

Use the same pattern for each command:

```bash
docker compose exec app-manager php artisan <command>
```

## Upgrade the stack

Always create a database backup before upgrading:

```bash
docker compose exec mysql \
  sh -c 'mysqldump -uroot -p"$MYSQL_ROOT_PASSWORD" --all-databases' \
  > backup.sql
```

Confirm that `backup.sql` exists and is not empty before continuing.

Then:

1. Update `WPROOFREADER_VERSION` or `APP_MANAGER_VERSION` in `.env`.
2. Download the new images and recreate the services:

   ```bash
   docker compose pull
   docker compose up -d
   ```

3. Check the service state and startup logs:

   ```bash
   docker compose ps --all
   docker compose logs db-manager app-manager
   ```

db-manager applies the changesets included in the selected WProofreader release,
and App-manager applies its own migrations during startup. Changesets that have
already run are skipped, so running `docker compose up -d` again is safe.

## HTTPS and public hostnames

The containers expose plain HTTP and bind to `127.0.0.1` by default. For any
deployment beyond a local evaluation, place a reverse proxy such as nginx,
Caddy, or Traefik in front of the stack and terminate TLS there. Keep the
loopback binding when the proxy runs on the same host. If your network design
requires another binding, change `BIND_ADDRESS` and restrict access with a
firewall or security group.

Set the public URLs in `.env` so App-manager generates correct links and the
browser reaches both services over HTTPS:

```bash
APP_MANAGER_URL=https://app-manager.example.com
APPSERVER_URL=https://wproofreader.example.com/wscservice/api
PROXY_TYPE=generic
```

`PROXY_TYPE` also accepts `aws` and `cloudflare`. Use the same scheme for both
public URLs; browsers block mixed HTTP and HTTPS content. App-manager continues
to use the internal Compose network when communicating with WProofreader Server,
so its internal address does not need to change.

## Change a database password

Which steps you need depends on who owns the account.

`appserver` and `app_service` are managed by db-manager. Change
`APPSERVER_DB_PASSWORD` or `SERVICE_DB_PASSWORD` in `.env` and run:

```bash
docker compose up -d
```

db-manager runs again, sets the new password on the existing account, and
Compose recreates WProofreader Server and App-manager with the new value.

`app_manager` and `root` are created by the MySQL image, which reads `.env`
only when the data volume is initialised. Changing them always takes the
manual steps: update MySQL first, then `.env`, then recreate the containers.

1. Open the MySQL client using the current root password:

   ```bash
   docker compose exec mysql \
     sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD"'
   ```

2. At the `mysql>` prompt, change the account. For example:

   ```sql
   ALTER USER 'app_manager'@'%'
     IDENTIFIED BY 'replace-with-new-password';
   ```

   The account-to-variable mapping is:

   | MySQL account | Host | Variable to update in `.env` |
   | --- | --- | --- |
   | `app_manager` | `%` | `APP_MANAGER_DB_PASSWORD` |
   | `app_service` | `%` | `SERVICE_DB_PASSWORD` |
   | `appserver` | `%` | `APPSERVER_DB_PASSWORD` |
   | `root` | `localhost` and `%` | `MYSQL_ROOT_PASSWORD` |

   When rotating the root password, update both the `root@localhost` and
   `root@%` accounts before changing `MYSQL_ROOT_PASSWORD`.

3. Exit the MySQL client, update the corresponding value in `.env`, and apply
   the change:

   ```bash
   docker compose up -d
   docker compose ps --all
   ```

If a password contains a single quote, escape it correctly for SQL or rotate it
through your normal database administration tooling.

## Troubleshooting

### db-manager exits with code 1

Read its logs first:

```bash
docker compose logs db-manager
```

Common causes are an incorrect `MYSQL_ROOT_PASSWORD`, mismatched image versions,
or MySQL taking longer than expected to initialize on a slow disk. After fixing
the cause, run `docker compose up -d` again.

### App-manager remains `starting` or becomes `unhealthy`

```bash
docker compose logs app-manager
```

App-manager waits up to two minutes for MySQL and then runs its migrations. Any
database connection or migration error appears in this log.

### A port is already in use

Change `APP_MANAGER_PORT` or `APPSERVER_PORT` in `.env`, then run:

```bash
docker compose up -d
```

### The setup token is invalid or expired

Setup tokens expire after 24 hours. Generate a replacement:

```bash
docker compose exec app-manager \
  php artisan app:setup-token --regenerate
```

### Start again from an empty installation

> **Warning:** The following command permanently removes both databases,
> WProofreader dictionaries, and App-manager storage.

```bash
docker compose down -v
docker compose up -d
```
