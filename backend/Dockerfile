<<<<<<< HEAD
FROM node:22-alpine
WORKDIR /app
ENV NODE_ENV=production
COPY package*.json ./
RUN npm ci --omit=dev
COPY src ./src
COPY sql ./sql
USER node
EXPOSE 3000
CMD ["node", "src/server.js"]
=======

FROM node:22-alpine
WORKDIR /app
ENV NODE_ENV=production
COPY package*.json ./
RUN npm ci --omit=dev
COPY src ./src
COPY sql ./sql
USER node
EXPOSE 3000
CMD ["node", "src/server.js"]
>>>>>>> c63214814ad55bba326332e22af94b7d700ab650
