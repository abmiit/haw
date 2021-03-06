Command = require './command'

path = require 'path'
showOutput = require './show-output'

defaultConfig = require './default-config'

class CLI extends Command
  configFiles: [
    path.resolve process.env.HOME, '.config', 'haw'
    path.resolve process.env.HOME, '.haw'
    'slug'
  ]

  usage: '''
    haw init
    haw init controller SomeController
    haw serve --port 1234
    haw serveStatic --port 1234
    haw build --config ./package.json --output ./build
  '''

  options: [
    ['config',  'c', 'Configuration file']
    ['root',    'r', 'Root from which to look for files', defaultConfig.root]
    ['port',    'p', 'Port on which to run the server', defaultConfig.port]
    ['output',  'o', 'Directory in which to build the site', defaultConfig.output]
    ['force',   'f', 'Overwrite any existing output directory', defaultConfig.force]
    ['quiet',   'q', 'Don\'t show any working info', defaultConfig.quiet]
    ['verbose', 'Q', 'Show lots of working info', defaultConfig.verbose]
    ['help',    'h', 'Print some help']
    ['version', 'v', 'Print the version number']
  ]

  modifyOptions: (options) ->
    super
    options._.unshift 'version' if options.version

  mergeConfigs: (configs..., options) ->
    configs.unshift defaultConfig
    configs.push options.config if 'config' of options
    super configs..., options

  version: ->
    console.log require(path.join __dirname, '..', 'package').version

  initialize: ([type]..., options) ->
    Initializer = require './initializer'
    initializer = new Initializer options
    showOutput initializer
    initializer.initialize type, options

  serve: ([port]..., options) ->
    port ?= options.port

    Server = require './server'
    exec = require 'easy-exec'

    server = new Server options
    showOutput server

    server.serve port

    try
      process.stdin.setRawMode true
      process.stdin.resume()

      process.stdin.on 'data', (data) ->
        switch data.toString()
          when 'o'
            console.log 'Opening browser'
            exec "open http://localhost:#{port}/index.html"
          when 'q', '\u0003' # Ctrl-C
            console.log 'Goodbye'
            process.exit()

      console.log 'Hit "o" to open your browser.'

  build: (options) ->
    Builder = require '../lib/builder'
    builder = new Builder options
    showOutput builder
    builder.build()

  serveStatic: (options) ->
    # clear existing default options that cause regeneration of files on each request
    options.generate = {}
    options.compile = {}
    options.mount = {}
    options.mount[options.output] = '/'

    @serve options

  # Command shortcuts:
  @::i = @::initialize
  @::init = @::initialize
  @::s = @::serve
  @::b = @::build

module.exports = CLI
