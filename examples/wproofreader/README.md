# Run WProofreader Server with MySQL

This folder provides a self-contained Docker Compose setup for WProofreader
Server with its database provider enabled. It runs MySQL, db-manager, and
WProofreader Server without Admin-panel.

Use this stack when WProofreader needs database-backed request statistics,
user-action statistics, and request validation, but you do not need the
Admin-panel UI. For the full management stack, use the
[Admin-panel Compose example](../admin-panel/README.md).

## What the stack includes

| Service | Image | What it does |
| --- | --- | --- |
| `mysql` | `mysql:8.4` | Stores the `cloud_service` database. |
| `db-manager` | `webspellchecker/db-manager` | Creates and migrates `cloud_service`, loads its seed data, and manages the `appserver` database account. It exits when finished. |
| `appserver` | `webspellchecker/wproofreader` | Runs WProofreader Server with its database provider enabled. |

Docker Compose waits for MySQL to become healthy, runs db-manager to completion,
and starts WProofreader only after provisioning succeeds.

## Before you begin

Make sure the host has:

- Docker Engine 24 or newer with the Compose plugin.
- A valid WProofreader license ticket.
- Enough memory for WProofreader Server. See the
  [installation requirements](https://docs.webspellchecker.com/display/WebSpellCheckerServer55x/Installation+requirements).
- Port `8080` free on the loopback interface, unless you change it in `.env`.

Run all commands in this guide from the `examples/wproofreader` directory.

## Configure and start the stack

1. Create the local environment file:

   ```bash
   cp .env.example .env
   ```

2. Set these required values in `.env`:

   | Variable | Purpose |
   | --- | --- |
   | `LICENSE_TICKET_ID` | Activates WProofreader Server. |
   | `MYSQL_ROOT_PASSWORD` | Lets db-manager create and migrate the database. |
   | `APPSERVER_DB_PASSWORD` | Password WProofreader uses for `cloud_service`. |

   Choose strong, unique passwords and keep `.env` private. MySQL and db-manager
   apply them to the database accounts; changing a value later requires the
   password-rotation procedure below.

3. Check the configuration and start it:

   ```bash
   docker compose config --quiet
   docker compose up -d
   ```

The first start may take several minutes while images are downloaded and MySQL
initializes. Check progress with:

```bash
docker compose ps --all
docker compose logs db-manager appserver
```

When startup is complete, `mysql` and `appserver` should be healthy and
`db-manager` should show `Exited (0)`. The server is available at
<http://localhost:8080/wscservice/>.

## Verify the server

Check the status endpoint:

```bash
curl 'http://localhost:8080/wscservice/api?cmd=status'
```

A successful response confirms that WProofreader is reachable and licensed.
The container health check only confirms that the process answers; an invalid
license can therefore leave the container healthy while API requests fail.

## Day-to-day operations

| Task | Command |
| --- | --- |
| Show all service state | `docker compose ps --all` |
| Follow all logs | `docker compose logs -f` |
| Follow WProofreader logs | `docker compose logs -f appserver` |
| Stop the stack | `docker compose stop` |
| Start stopped containers | `docker compose start` |
| Remove containers while keeping data | `docker compose down` |

> **Warning:** `docker compose down -v` permanently deletes the database and
> WProofreader dictionaries.

## Upgrade

Create a database backup first:

```bash
docker compose exec mysql \
  sh -c 'mysqldump -uroot -p"$MYSQL_ROOT_PASSWORD" --all-databases' \
  > backup.sql
```

Confirm that `backup.sql` is not empty. Then update `WPROOFREADER_VERSION` in
`.env` and run:

```bash
docker compose pull
docker compose up -d
docker compose ps --all
docker compose logs db-manager appserver
```

WProofreader Server and db-manager are released together and should normally use
the same version. db-manager applies only migrations that have not already run.

## Change a database password

To rotate the `appserver` password, change `APPSERVER_DB_PASSWORD` in `.env` and
run `docker compose up -d`. Compose recreates db-manager, which updates the
account password and grants before recreating WProofreader with the new value.

To rotate the root password, change it in MySQL first, then update
`MYSQL_ROOT_PASSWORD` in `.env` and recreate the services. Changing only `.env`
does not update an existing MySQL account.

## Public access and HTTPS

The example binds plain HTTP to `127.0.0.1`. For remote access, put a TLS reverse
proxy or load balancer in front of the stack. If the proxy runs elsewhere,
change `BIND_ADDRESS` and restrict the published port with a firewall or security
group.

## Troubleshooting

If db-manager exits with code 1, inspect `docker compose logs db-manager`. Common
causes are incorrect database passwords, mismatched WProofreader and db-manager
versions, or slow MySQL initialization. Fix the cause and run
`docker compose up -d` again.

If the server reports `License is absent`, correct `LICENSE_TICKET_ID` and run:

```bash
docker compose up -d appserver
docker compose logs appserver
```

License activation requires outbound access to the WebSpellChecker license
server. See the proxy settings in the [main guide](../../README.md) when outbound
traffic must use a proxy.
