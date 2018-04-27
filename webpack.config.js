const fs = require('fs')
const HtmlWebpackPlugin = require('html-webpack-plugin')
const MiniCssExtractPlugin = require('mini-css-extract-plugin')
const UglifyJsPlugin = require('uglifyjs-webpack-plugin')
const StaticWebsite = require('in-memory-website').StaticWebsite

function assetKeyToPath(assetKey) {
  return assetKey.replace(/\.html$/, '')
}

function assetKeyToContentType(assetKey) {
  if (/\.js$/.test(assetKey)) {
    return 'application/javascript'
  }
  if (/\.css$/.test(assetKey)) {
    return 'text/css'
  }
  if (/\.html$/.test(assetKey)) {
    return 'text/html; charset=utf-8'
  }
  if (/\.js\.map$/.test(assetKey)) {
    return 'application/json'
  }
  return 'application/octet-stream'
}

function assetKeyToCacheControl(assetKey) {
  if (/\.html$/.test(assetKey)) {
    return 'public, max-age=30'
  } else {
    return 'public, max-age=31536000'
  }
}

class WriteInMemoryWebsitePlugin {
  constructor(options) {
    if (!options.filename) throw new Error("Missing 'filename' option")
    this.filename = options.filename
    this.staticAssets = options.staticAssets || []
  }

  apply(compiler) {
    const idToAsset = {} // Hash of asset ID (e.g., "show.html") to StaticEndpoint

    compiler.plugin('emit', (compilation, callback) => {
      Object.keys(compilation.assets).forEach(assetKey => {
        // show.abcdefabcdefabcdefab.js => show.js
        const assetId = assetKey.replace(/\.[0-9a-f]{20}\./, '.')

        // show.abcdefabcdefabcdefab.js => /show.abcdefabcdefabcdefab.js
        const assetPath = assetKeyToPath(assetKey)

        const asset = compilation.assets[assetKey]

        const body = Buffer.from(asset.source())

        idToAsset[assetId] = {
          path: `/${assetPath}`,
          body: body,
          headers: {
            'Content-Type': assetKeyToContentType(assetKey),
            'Content-Length': String(body.length),
            'Cache-Control': assetKeyToCacheControl(assetKey),
          }
        }
      })

      const endpoints = this.staticAssets.concat(Object.keys(idToAsset).map(k => idToAsset[k]))
      const staticWebsite = new StaticWebsite(endpoints)
      const buf = staticWebsite.toBuffer()

      console.log(`Writing static website with ${endpoints.length} endpoints to ${this.filename}`)

      fs.writeFile(this.filename, buf, callback)
    })
  }
}

module.exports = {
  context: __dirname + '/app',
  devtool: 'source-map',
  entry: './show.coffee',
  output: {
    path: __dirname + '/dist',
    filename: 'show.[chunkhash].js',
  },
  resolve: {
    extensions: [ '.js', '.coffee', '.pug' ],
  },
  mode: 'production',
  module: {
    rules: [
      {
        test: /\.coffee$/,
        use: [
          {
            loader: 'coffee-loader',
            options: { sourceMap: true },
          },
        ],
      },
      {
        test: /\.pug$/,
        use: [ { loader: 'pug-loader', }, ],
      },
      {
        test: /\.(woff|woff2|png)$/,
        use: 'base64-inline-loader',
      },
      {
        test: /\.(css|scss)$/,
        use: [
          MiniCssExtractPlugin.loader,
          'css-loader',
          'sass-loader',
        ],
      },
    ],
  },
  plugins: [
    new MiniCssExtractPlugin({
      filename: '[name].[contenthash].css',
    }),
    new HtmlWebpackPlugin({
      title: 'Entity Filter',
      filename: 'show.html',
      template: 'show.html',
      cache: false,
    }),
    new UglifyJsPlugin({
      uglifyOptions: {
        compress: {
          ecma: 6,
        },
        output: {
          ecma: 6,
        },
      },
    }),
    new WriteInMemoryWebsitePlugin({
      filename: 'website.data',
      staticAssets: [
        {
          path: '/metadata',
          body: Buffer.from('{}'),
          headers: {
            'Content-Type': 'application/json',
            'Cache-Control': 'public, max-age=60',
            'Access-Control-Allow-Origin': '*',
          },
        },
      ],
    }),
  ]
}
