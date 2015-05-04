gulp = require('gulp')
gutil = require('gulp-util')
jade = require('gulp-jade')
less = require('gulp-less')
plumber = require('gulp-plumber')
rename = require('gulp-rename')
rimraf = require('gulp-rimraf')
source = require('vinyl-source-stream')
supervisor = require('gulp-supervisor')

browserify = require('browserify')
watchify = require('watchify')
browserifyJade = require('browserify-jade')

uploadToAws = (done) ->
  s3 = require('s3')
  client = s3.createClient()
  upload = client.uploadDir
    localDir: 'dist'
    deleteRemoved: true
    s3Params:
      Bucket: 'overview-multi-search'
      Prefix: ''
      ACL: 'public-read'
      CacheControl: 'no-cache'
    getS3Params: (localFile, stat, callback) ->
      if localFile in [ 'dist/show', 'dist/metadata' ]
        callback(null, ContentType: 'text/html')
      else
        callback(null, {})
  upload.on 'error', (err) ->
    console.error("Unable to upload: ", err.stack)
  upload.on 'fileUploadStart', (__, s3Key) ->
    console.log("Uploading #{s3Key}")
  upload.on('end', done)

startBrowserify = (watch) ->
  options =
    cache: {}
    packageCache: {}
    fullPaths: true
    entries: [ './js/main.coffee' ]
    extensions: [ '.coffee', '.js', '.json', '.jade' ]
    debug: true # enable source maps

  bundler = browserify(options)
  bundler.transform('coffeeify')
  bundler.transform(browserifyJade.jade({
    pretty: false
  }))

  rebundle = ->
    bundler.bundle()
      .on('error', (e) -> gutil.log('Browserify error:', e.message))
      .pipe(source('main.js'))
      .pipe(gulp.dest('dist/js'))

  if watch
    bundler = watchify(bundler)
    bundler.on('update', rebundle)
  else
    bundler.plugin 'minifyify',
      map: 'main.js.map.json'
      compressPath: process.cwd()
      output: 'dist/js/main.js.map.json'

  rebundle()

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
gulp.task('js', [ 'clean' ], -> startBrowserify(false))
gulp.task('watch-js', [ 'clean' ], -> startBrowserify(true))

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
  supervisor("app/main.coffee", {
    watch: [ 'app' ]
    extensions: [ 'coffee', 'js', 'jade' ]
  })

gulp.task 'default', [ 'watch', 'server' ]

gulp.task 'prod', [ 'css', 'js', 'jade', 'public' ]

gulp.task 'deploy', [ 'prod' ], (done) ->
  uploadToAws(done)
