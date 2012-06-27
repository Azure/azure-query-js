# Build query.js

fs = require 'fs'
{print} = require 'util'
{spawn} = require 'child_process'

run = (name, args, callback) ->
    proc = spawn name, args
    proc.stderr.on 'data', (data) ->
        process.stderr.write data.toString()
    proc.stdout.on 'data', (data) ->
        print data.toString()
    proc.on 'exit', (code) ->
        callback?() if code == 0

build = (callback) ->
    print 'building src/\n'
    run 'coffee', ['-c', '-o', 'lib', 'src'], callback

task 'build', 'Build lib/ from src/', ->
    build()

task 'clean', 'Clean lib/', ->
    print 'cleaning lib/\n'
    run 'rm', ['-r', './lib']

task 'watch', 'Watch src/ for changes', ->
    print 'building and watcing src/\n'
    run 'coffee', ['-w', '-c', '-o', 'lib', 'src']

task 'jshint', 'Verify src/ with jshint', ->
    build ->
        run './node_modules/.bin/jshint', ['--config', '.jshint', './lib']

task 'test', 'Run the unit tests', ->
    build ->
        print 'Running unit tests\n'
        run './node_modules/.bin/mocha'

task 'testdbg', 'Run the unit tests under the debugger', ->
    build ->
        print 'Running unit tests under the debugger\n'
        run './node_modules/.bin/mocha', ['debug', '--debug-brk']
