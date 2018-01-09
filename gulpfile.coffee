childProcess = require('child_process')
exorcist = require('exorcist')
fs = require('fs')
gulp = require('gulp')
gutil = require('gulp-util')
jade = require('gulp-jade')
less = require('gulp-less')
plumber = require('gulp-plumber')
rename = require('gulp-rename')
rimraf = require('gulp-rimraf')
supervisor = require('gulp-supervisor')

browserify = require('browserify')
watchify = require('watchify')
pugify = require('pugify')

uploadToAws = (done) ->
  childProcess.spawnSync('aws', [
    's3', 'sync',
    "#{__dirname}/dist/fonts",
    "s3://#{process.env.S3_BUCKET}/fonts",
    '--acl', 'public-read',
  ])
  childProcess.spawnSync('aws', [
    's3', 'sync',
    "#{__dirname}/dist/css",
    "s3://#{process.env.S3_BUCKET}/css",
    '--acl', 'public-read',
  ])
  childProcess.spawnSync('aws', [
    's3', 'sync',
    "#{__dirname}/dist/js",
    "s3://#{process.env.S3_BUCKET}/js",
    '--acl', 'public-read',
  ])
  childProcess.spawnSync('aws', [
    's3', 'cp',
    "#{__dirname}/dist/show",
    "s3://#{process.env.S3_BUCKET}/show",
    '--acl', 'public-read',
    '--content-type', 'text/html; charset=utf-8',
  ])
  childProcess.spawnSync('aws', [
    's3', 'cp',
    "#{__dirname}/dist/metadata",
    "s3://#{process.env.S3_BUCKET}/metadata",
    '--acl', 'public-read',
    '--content-type', 'text/plain; charset=utf-8',
  ])

  done()

startBrowserify = (watch) ->
  (done) ->
    options =
      cache: {}
      packageCache: {}
      fullPaths: true
      extensions: [ '.coffee', '.js', '.json', '.jade' ]
      debug: true # enable source maps

    bundler = browserify(options)
    bundler.transform('coffeeify')
    bundler.transform(pugify.pug({
      pretty: false
    }))
    bundler.transform('uglifyify', global: true)

    rebundle = (done) ->
      fs.mkdir "#{__dirname}/dist", (err) =>
        return done(err) if err && err.code != 'EEXIST'

        fs.mkdir "#{__dirname}/dist/js", (err) =>
          return done(err) if err && err.code != 'EEXIST'

          returned = false

          bundler
            .require(require.resolve('./js/main.coffee'), entry: true)
            .bundle()
            .pipe(plumber())
            .pipe(exorcist("#{__dirname}/dist/js/main.js.map", '/js/main.js.map'))
            .pipe(fs.createWriteStream("#{__dirname}/dist/js/main.js"))
            .on 'error', (err) ->
              done(err) if !returned
              returned = true
            .on 'finish', () ->
              done(null) if !returned

    if watch
      bundler = watchify(bundler)
      bundler.on('update', rebundle)
      rebundle() # and never call done()
    else
      rebundle(done)

# All files go in dist/
gulp.task 'clean', ->
  gulp.src('./dist', read: false)
    .pipe(rimraf(force: true))

# ./css/**/*.less -> ./dist/css/main.less
doCss = ->
  gulp.src('css/main.less')
    .pipe(plumber())
    .pipe(less())
    .pipe(gulp.dest('dist/css'))
gulp.task('css', [ 'clean' ], doCss)
gulp.task('css-noclean', doCss)
gulp.task 'watch-css', [ 'css' ], ->
  gulp.watch('css/**/*', [ 'css-noclean' ])

# ./js/**/*.(coffee|js) -> ./dist/app.js
gulp.task('js', [ 'clean' ], startBrowserify(false))
gulp.task('watch-js', [ 'clean' ], startBrowserify(true))

# ./public/**/* -> ./dist/**/*
doPublic = ->
  gulp.src('public/**/*')
    .pipe(gulp.dest('dist'))
gulp.task('public', [ 'clean' ], doPublic)
gulp.task('public-noclean', doPublic)
gulp.task 'watch-public', [ 'public' ], ->
  gulp.watch('public/**/*', [ 'public-noclean' ])

# ./jade/**/*.jade -> ./dist/**/*.html
doJade = ->
  gulp.src('jade/**/*.jade')
    .pipe(plumber())
    .pipe(jade({
      pretty: true
    }))
    .pipe(rename((path) -> path.extname = '')) # remove ".html", so we don't need redirects
    .pipe(gulp.dest('dist'))
gulp.task('jade', [ 'clean' ], doJade)
gulp.task('jade-noclean', doJade)
gulp.task 'watch-jade', [ 'jade' ], ->
  gulp.watch('./jade/**/*.jade', [ 'jade-noclean' ])

gulp.task 'watch', [ 'watch-css', 'watch-js', 'watch-jade', 'watch-public' ], ->

gulp.task 'server', ->
  supervisor("server.js", {
    watch: [ 'server.js' ]
    extensions: [ 'coffee', 'js', 'jade' ]
  })

gulp.task 'default', [ 'watch', 'server' ]

gulp.task 'prod', [ 'css', 'js', 'jade', 'public' ]

gulp.task 'deploy', [ 'prod' ], (done) ->
  uploadToAws(done)

process.on('SIGINT', () => process.exit(0)) # so user can always Ctrl+C
