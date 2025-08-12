FROM node:20.11.0
WORKDIR /app
COPY . .
RUN npm install
RUN npm run dev

RUN npm install -g serve
EXPOSE 3000
CMD ["serve", "-s", "build"]