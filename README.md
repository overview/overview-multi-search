overview-multi-search
=====================

This [Overview](https://github.com/overview/overview-server) plugin uses
nothing but flat files. Any web server can serve it.

Running on a dev machine
------------------------

1. Run [overview-server](https://github.com/overview/overview-server)'s `./dev`
1.`Run `./dev` in this directory, in a separate shell.
1. In Overview (http://localhost:9000), create a plugin with url `https://localhost:3334` and Overview URL `http://overview-dev`.

Then there are the tests:

1. `./npm test` runs unit tests
1. `./integration-tests/run` runs integration tests (assuming you're running the dev-mode processes)
1. `./integration-tests/run-browser spec/multi_search_spec.rb` runs tests in a web browser viewed with `vncviewer` (assuming you're running the dev-mode processes)
1. `./integration-tests/run-in-docker-compose` runs a clean test environment (useful for continuous integration)

Releasing and deploying
-----------------------

1. Run `./integration-tests/run-in-docker-compose`
1. `./release 1.0.1` (or whatever version) to publish a Docker image
1. `AWS_ACCESS_KEY_ID=... AWS_SECRET_ACCESS_KEY=... S3_BUCKET=... ./deploy` to deploy to an S3 bucket. (The production version is in the `overview-multi-search` bucket.)
