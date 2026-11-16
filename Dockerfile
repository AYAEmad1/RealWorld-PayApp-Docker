# syntax=docker/dockerfile:1
#
# Cypress Real World App (React + Express) - multi-stage Docker build
#   deps       -> installs the Node dependencies once (shared by the next stages)
#   web-build  -> builds the React frontend with Vite into static files
#   web        -> final image #1: tiny nginx serving the static frontend
#   api        -> final image #2: the Express API (TypeScript, run with ts-node)
#
# Build one image:  docker build --target web -t payapp-web .
#                   docker build --target api -t payapp-api .
ARG NODE_VERSION=22

# ---------------------------------------------------------------------------
# Stage 1: dependencies
# ---------------------------------------------------------------------------
FROM node:${NODE_VERSION}-slim AS deps

# CYPRESS_INSTALL_BINARY=0 -> do not download the ~200 MB Cypress test runner (not needed to run the app)
# HUSKY=0                  -> skip git hooks (there is no .git folder inside the image)
ENV CYPRESS_INSTALL_BINARY=0 \
    HUSKY=0 \
    CI=true

WORKDIR /app

# Copy only the manifests first, so this slow layer is cached until the dependencies change.
COPY src/package.json src/yarn.lock src/.yarnrc ./
COPY src/patches ./patches
RUN yarn install --frozen-lockfile

# ---------------------------------------------------------------------------
# Stage 2: build the React frontend
# ---------------------------------------------------------------------------
FROM deps AS web-build

# The frontend calls the API at http://localhost:<VITE_BACKEND_PORT> (the address your browser uses).
ARG VITE_BACKEND_PORT=3001
ENV VITE_BACKEND_PORT=${VITE_BACKEND_PORT}

COPY src/ ./
# Same as the project's vite.config.ts, without the lint/coverage plugins that are only for development.
COPY vite.docker.config.ts ./
RUN npx vite build --config vite.docker.config.ts

# ---------------------------------------------------------------------------
# Stage 3a: final frontend image (nginx + static files)
# ---------------------------------------------------------------------------
FROM nginx:1.27-alpine AS web

LABEL org.opencontainers.image.title="RealWorld-PayApp-Docker (web)" \
      org.opencontainers.image.source="https://github.com/cypress-io/cypress-realworld-app" \
      org.opencontainers.image.licenses="MIT"

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=web-build /app/build /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -q --spider http://127.0.0.1/ || exit 1

# ---------------------------------------------------------------------------
# Stage 3b: final API image
# ---------------------------------------------------------------------------
FROM deps AS api

LABEL org.opencontainers.image.title="RealWorld-PayApp-Docker (api)" \
      org.opencontainers.image.source="https://github.com/cypress-io/cypress-realworld-app" \
      org.opencontainers.image.licenses="MIT"

# PORT is the URL port of the FRONTEND (the API only accepts requests from http://localhost:PORT).
# production mode also turns off the test-only /testData routes.
ENV NODE_ENV=production \
    PORT=3000 \
    VITE_BACKEND_PORT=3001 \
    TS_NODE_TRANSPILE_ONLY=true

COPY src/ ./

# The API imports ../src/aws-exports (an AWS Amplify file that is not in the repository).
# Create an empty stub when it is missing so the server can start without AWS.
RUN [ -f src/aws-exports.js ] || [ -f src/aws-exports.ts ] || \
    echo "const awsmobile = { Auth: { Cognito: { userPoolId: '', userPoolClientId: '', identityPoolId: '' } } }; module.exports = awsmobile; module.exports.default = awsmobile;" > src/aws-exports.js

# Start from a clean copy of the demo data and let the non-root user write to it.
RUN cp data/database-seed.json data/database.json \
    && chown -R node:node /app/data

USER node

EXPOSE 3001

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=5 \
    CMD node -e "fetch('http://127.0.0.1:3001/').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

CMD ["node_modules/.bin/ts-node", "--files", "-P", "tsconfig.tsnode.json", "backend/app.ts"]