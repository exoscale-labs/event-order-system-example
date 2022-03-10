FROM node:14-alpine

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm install

COPY ./src ./src
COPY ./ca ./ca

RUN npm ci --only=production

EXPOSE 8080

ENV HOST=0.0.0.0

CMD [ "npm", "start" ]