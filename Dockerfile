FROM node:9.0.0-alpine

# use changes to package.json to force Docker not to use the cache
# when we change our application's nodejs dependencies:
COPY package.json package-lock.json /opt/app/
RUN cd /opt/app && npm install --production

# From here we load our application's code in, therefore the previous docker
# "layer" thats been cached will be used if possible
COPY server.js /opt/app/
COPY dist /opt/app/dist

ENV PORT 80
EXPOSE 80
WORKDIR /opt/app
CMD /usr/local/bin/node /opt/app/server.js

