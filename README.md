overview-multi-search
=====================

This [Overview](https://github.com/overview/overview-server) plugin uses
nothing but flat files. Any web server can serve it.

Running on a dev machine
------------------------

1. `npm install`
2. `npm install -g gulp`
3. `gulp server`
4. Point your local Overview instance to `http://localhost:9001`

Deploying to S3
---------------

1. Run it on your dev machine
2. Set `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables
3. `gulp deploy`
