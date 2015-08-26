overview-multi-search
=====================

This [Overview](https://github.com/overview/overview-server) plugin uses
nothing but flat files. Any web server can serve it.

Running as a docker image
-------------------------

1. Run the image, mapping port 3000 to a free port on your host

Running on a dev machine
------------------------

1. `npm install`
2. `npm install -g gulp`
3. `gulp server`
4. Point your local Overview instance to `http://localhost:3000`

Deploying to S3
---------------

1. Run it on your dev machine
2. Set `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables
3. `gulp deploy`
