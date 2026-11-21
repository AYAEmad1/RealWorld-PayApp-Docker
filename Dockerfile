# syntax=docker/dockerfile:1


ARG NODE_VERSION=22


FROM node:${NODE_VERSION}-slim AS deps


ENV CYPRESS_INSTALL_BINARY=0 \
    HUSKY=0 \
    CI=true

WORKDIR /app


COPY src/package.json src/yarn.lock src/.yarnrc ./
COPY src/patches ./patches
RUN yarn install --frozen-lockfile


FROM deps AS web-build


ARG VITE_BACKEND_PORT=3001
ENV VITE_BACKEND_PORT=${VITE_BACKEND_PORT}

COPY src/ ./

COPY vite.docker.config.ts ./
RUN npx vite build --config vite.docker.config.ts


FROM nginx:1.27-alpine AS web

LABEL org.opencontainers.image.title="RealWorld-PayApp-Docker (web)" \
      org.opencontainers.image.source="https://github.com/cypress-io/cypress-realworld-app" \
      org.opencontainers.image.licenses="MIT"

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=web-build /app/build /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -q --spider http://127.0.0.1/ || exit 1


FROM deps AS api

LABEL org.opencontainers.image.title="RealWorld-PayApp-Docker (api)" \
      org.opencontainers.image.source="https://github.com/cypress-io/cypress-realworld-app" \
      org.opencontainers.image.licenses="MIT"


ENV NODE_ENV=production \
    PORT=3000 \
    VITE_BACKEND_PORT=3001 \
    TS_NODE_TRANSPILE_ONLY=true

COPY src/ ./


RUN [ -f src/aws-exports.js ] || [ -f src/aws-exports.ts ] || \
    echo "const awsmobile = { Auth: { Cognito: { userPoolId: '', userPoolClientId: '', identityPoolId: '' } } }; module.exports = awsmobile; module.exports.default = awsmobile;" > src/aws-exports.js


RUN cp data/database-seed.json data/database.json \
    && chown -R node:node /app/data

USER node

EXPOSE 3001

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=5 \
    CMD node -e "fetch('http://127.0.0.1:3001/').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

CMD ["node_modules/.bin/ts-node", "--files", "-P", "tsconfig.tsnode.json", "backend/app.ts"]