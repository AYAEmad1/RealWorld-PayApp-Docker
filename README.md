# RealWorld-PayApp-Docker

A **Dockerized** version of the open-source [Cypress Real World App](https://github.com/cypress-io/cypress-realworld-app): a Venmo-style payment app with a React frontend and an Express.js API. One command builds both images and starts the website with ready-made demo data.

## About the original project

> This application is purely for demonstration and educational purposes. Its setup and configuration resemble typical real-world applications, but it's not a full-fledged production system. Use this app to learn, experiment, tinker, and practice application testing with Cypress.
>
> — from the original README by [Cypress.io](https://github.com/cypress-io/cypress-realworld-app), licensed under the **MIT License** (see [`LICENSE`](LICENSE)).

The original application code lives unchanged in `src/` (its own README is `src/README.md`).

## What I added (Docker work)

- **Multi-stage `Dockerfile`**: installs dependencies once, builds the React frontend with Vite, and produces two images (nginx for the web, Node for the API).
- **`docker-compose.yml`**: runs `web` and `api` together, with healthchecks and `depends_on: service_healthy`.
- **Named volume** (`api_data`) so the demo data survives restarts.
- **`nginx.conf`** and **`vite.docker.config.ts`** for the production build.
- **`Makefile`** shortcuts and a **GitHub Actions** workflow that builds and smoke-tests the stack.
- A placeholder `aws-exports` file created in the API image, so the server starts without AWS.

## What the app does

- Sign in with a demo account (or create a new one) and link a bank account
- **Pay** or **request money** from other users, with a note and amount
- See the public, friends and personal **transaction feeds**
- Like and comment on transactions, and receive **notifications**

## Tech stack

| Layer | Technology |
|---|---|
| Frontend | React 18, Material UI, XState, Vite |
| Backend | Node.js 22, Express, TypeScript (ts-node), Passport |
| Data | JSON file database (lowdb), demo data included |
| Containers | Docker, Docker Compose, multi-stage build, nginx |
| CI | GitHub Actions |

## Repository structure

```
.
├── src/                      # the original application (frontend + backend + demo data)
├── docs/
│   ├── notes.md              # technical notes
│   └── screenshots/          # assignment evidence
├── .github/workflows/docker-ci.yml
├── Dockerfile                # multi-stage build: deps -> web-build -> web (nginx) / api
├── docker-compose.yml        # two services: web + api
├── nginx.conf                # serves the React app (single-page-app fallback)
├── vite.docker.config.ts     # production build config used by the Dockerfile
├── Makefile                  # make build / run / stop / clean
├── .dockerignore
├── .gitignore
├── README.md
└── LICENSE
```

## Build and run with Docker

**Requirements:** Docker Desktop (or Docker Engine) with Docker Compose v2, and `git`. You do **not** need Node.js or Yarn.

```bash
# 1. Clone
git clone https://github.com/AYAEmad1/RealWorld-PayApp-Docker.git
cd RealWorld-PayApp-Docker

# 2. Build and start (first build takes a few minutes)
docker compose up -d --build

# 3. Check that both containers are healthy
docker compose ps
```

Or with Make: `make run`.

## How to test it

Open **http://localhost:3000** in your browser (use `localhost`, not `127.0.0.1`).

1. Click **Sign In** and log in with the demo account: username `Heath93`, password `s3cret`.
2. The home page shows the transaction feeds with demo data.
3. Click **New** and send a payment or a request to another user.
4. Open a transaction, add a like or a comment, then check **Notifications**.

Check the API directly:

```bash
curl http://localhost:3001/
curl -X POST -H "Content-Type: application/json" \
  -d '{"username":"Heath93","password":"s3cret"}' http://localhost:3001/login
```

## Configuration notes

| Service | Container port | Host port | Purpose |
|---|---|---|---|
| `web` | 80 | **3000** | React frontend (nginx) |
| `api` | 3001 | **3001** | Express API |

- The frontend calls the API at `http://localhost:3001` (compiled into the frontend), and the API only accepts requests from `http://localhost:3000`. **Keep both ports as they are.**
- No secrets or environment variables are required.
- Demo data is stored in the named volume `api_data`, so payments survive restarts.

## Stop and clean up

```bash
docker compose down        # stop and remove containers (data is kept)          | make stop
docker compose down -v     # also delete the data volume (resets demo data)    | make clean
docker image rm payapp-web:latest payapp-api:latest   # remove the built images
```

## Troubleshooting

- **Login fails or the page stays empty:** open `http://localhost:3000` (not another port or `127.0.0.1`) and check that `docker compose ps` shows both containers `healthy`.
- **Port already in use:** stop the program using port 3000 or 3001, then run `docker compose up -d` again.
- **Fresh demo data:** `docker compose down -v && docker compose up -d`.
- **API unhealthy:** read the logs with `docker logs payapp-api`.

## Continuous integration

`.github/workflows/docker-ci.yml` runs the unit tests (non-blocking), builds both images, starts the stack with Docker Compose, waits for the healthchecks, and smoke-tests the frontend, the API and the demo login on every push and pull request.

## Attribution and license

This repository is based on [cypress-io/cypress-realworld-app](https://github.com/cypress-io/cypress-realworld-app) by Cypress.io, released under the [MIT License](LICENSE). The application code in `src/` is the original project; the Docker setup and documentation were added for a university DevOps assignment..