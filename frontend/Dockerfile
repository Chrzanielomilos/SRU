######## ETAP 1: deps – instalacja zależności ########
FROM node:20.11.0 AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --silent

######## ETAP 2: builder – budowanie aplikacji ########
FROM node:20.11.0 AS builder
WORKDIR /app
# używamy node_modules z etapu deps
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

######## ETAP 3: production – serwowanie ########
FROM node:20.11.0 AS runner
WORKDIR /app
ENV NODE_ENV=production
# kopiujemy artefakty
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
EXPOSE 3000
CMD ["npx", "next", "start"]
#CMD ["serve", "-s", "build"]



#FROM node:20.11.0
#WORKDIR /app
#COPY . .
#RUN npm install
#RUN npm run dev
#RUN npm install -g serve
#EXPOSE 3000
#CMD ["serve", "-s", "build"]