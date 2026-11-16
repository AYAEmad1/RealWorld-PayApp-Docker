# RealWorld-PayApp-Docker

A **Dockerized** version of the open-source https://github.com/cypress-io/cypress-realworld-app: a Venmo-style payment app with a React frontend and an Express.js API. One command builds both images and starts the website with ready-made demo data.

## About the original project

> This application is purely for demonstration and educational purposes. Its setup and configuration resemble typical real-world applications, but it's not a full-fledged production system. Use this app to learn, experiment, tinker, and practice application testing with Cypress.
>
> — from the original README by https://github.com/cypress-io/cypress-realworld-app, licensed under the **MIT License** (see LICENSE).

The original application code lives unchanged in `src/` (its own README is `src/README.md`).

## What I added (Docker work)

- **Multi-stage `Dockerfile`**: installs dependencies once, builds the React frontend with Vite, and produces two images (nginx for the web and Node.js for the API).
- **`docker-compose.yml`**: runs `web` and `api` together, with healthchecks and `depends_on: service_healthy`.
- **Named volume** (`api_data`) so the demo data survives restarts.
- **`nginx.conf`** and **`vite.docker.config.ts`** for the production build.
- **`Makefile`** shortcuts for building, running, and managing the Docker environment.
- A placeholder `aws-exports` file created in the API image, so the server starts without AWS.

## What the app does

- Sign in with a demo account (or create a new one) and link a bank account.
- **Pay** or **request money** from other users, with a note and amount.
- View public, friends, and personal **transaction feeds**.
- Like and comment on transactions and receive **notifications**.

## Tech Stack

| Layer | Technology |
|---------|------------|
| Frontend | React 18, Material UI, XState, Vite |
| Backend | Node.js 22, Express, TypeScript (ts-node), Passport |
| Data | JSON file database (lowdb), demo data included |
| Containers | Docker, Docker Compose, multi-stage build, nginx |
| Version Control | Git and GitHub |

## Repository Structure

```text
.
├── docs/
│   ├── notes.md
│   └── screenshots/
├── src/
├── .dockerignore
├── .gitignore
├── docker-compose.yml
├── Dockerfile
├── LICENSE
├── Makefile
├── nginx.conf
├── README.md
└── vite.docker.config.ts
```

## Build and Run with Docker

**Requirements:** Docker Desktop (or Docker Engine) with Docker Compose v2 and Git. You do **not** need Node.js or Yarn.

```bash
# Clone the repository
git clone https://github.com/AYAEmad1/RealWorld-PayApp-Docker.git
cd RealWorld-PayApp-Docker

# Build and start the application
docker compose up -d --build

# Verify that both containers are healthy
docker compose ps
```

Or use:

```bash
make run
```

## How to Test

Open:

```text
http://localhost:3000
```

in your browser.

1. Click **Sign In**.
2. Log in with:
   - Username: `Heath93`
   - Password: `s3cret`
3. Browse the transaction feed.
4. Create a payment or request.
5. Like or comment on transactions.
6. Check notifications.

You can also test the API directly:

```bash
curl http://localhost:3001/

curl -X POST -H "Content-Type: application/json" \
  -d '{"username":"Heath93","password":"s3cret"}' \
  http://localhost:3001/login
```

## Configuration Notes

| Service | Container Port | Host Port | Purpose |
|---------|---------------|-----------|---------|
| `web` | 80 | **3000** | React frontend (nginx) |
| `api` | 3001 | **3001** | Express API |

- The frontend calls the API at `http://localhost:3001\`.
- The API only accepts requests from `http://localhost:3000\`.
- Keep both ports unchanged.
- No secrets or environment variables are required.
- Demo data is stored in the named volume `api_data`, so data survives container restarts.

## Stop and Clean Up

```bash
docker compose down

docker compose down -v

docker image rm payapp-web:latest payapp-api:latest
```

## Troubleshooting

- **Login fails or the page remains empty:** verify that both containers are healthy using `docker compose ps`.
- **Port already in use:** stop the process using port 3000 or 3001 and restart the containers.
- **Reset demo data:** run `docker compose down -v` and start again.
- **API unhealthy:** inspect container logs with `docker logs payapp-api`.

## Attribution and License

This repository is based on https://github.com/cypress-io/cypress-realworld-app by Cypress.io, released under the LICENSE.

The application code in `src/` is the original project. The Docker setup and documentation were added for a university DevOps assignment.