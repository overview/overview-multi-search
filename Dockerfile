# common: base image
FROM alpine:3.7 AS common

ENV PORT 80
EXPOSE 80
WORKDIR /app

RUN apk --update --no-cache add nodejs


# development: what we use during development
FROM common AS development

# nodejs-npm: to install packages
# aws-cli: to deploy to S3
RUN apk --update --no-cache add \
      nodejs-npm \
      python3 \
  && pip3 install awscli

# use changes to package.json to force Docker not to use the cache
# when we change our application's nodejs dependencies:
COPY package.json package-lock.json /app/
RUN npm install

## We read files from here:
# (these are commented out because they break Docker Hub's auto-builder. TODO
# stop auto-building on Docker Hub so we can set target=production)
#VOLUME /app/jade
#VOLUME /app/js
#VOLUME /app/test
#VOLUME /app/css
#VOLUME /app/gulpfile.js
#VOLUME /app/server.js
#VOLUME /app/public

ENV PATH "/app/node_modules/.bin:/usr/local/bin:/usr/bin:/bin:/sbin"

# build: similar to development, but just builds and writes to dist/
FROM common AS build

# Compile dist/ directory: all our static files
COPY . /app/
RUN set -x \
      && apk add nodejs-npm \
      && npm install \
      && node_modules/.bin/gulp prod \
      && rm -rf node_modules \
      && npm install --production


# production: web server
FROM common AS production

COPY server.js package.json package-lock.json /app/
COPY --from=build /app/node_modules/ /app/node_modules/
COPY --from=build /app/dist/ /app/dist/

CMD [ "/usr/bin/node", "/app/server.js" ]
