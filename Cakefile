#
# Cakefile
#
# Copyright (c) 2012 Lee Olayvar <leeolayvar@gmail.com>
# MIT Licensed
#
{spawn} = require 'child_process'

bork = require 'bork'



COFFEE_BIN = path.join 'node_modules', 'coffee-script', 'bin', 'coffee'
MOCHA_BIN = path.join 'node_modules', 'mocha', 'bin', 'mocha'




# (cmd, args=[], callback=->) -> undefined
#
# Params:
#   cmd: The command to execute.
#   args: A list of args to pass to the process
#   callback: Callback on process exit.
#
# Desc:
#   A simple process launcher that streams output.
exec = (cmd, args=[], cb=->) ->
  bin = spawn cmd, args
  bin.stdout.on 'data', (data) ->
    process.stdout.write data
  bin.stderr.on 'data', (data) ->
    process.stderr.write data
  bin.on 'exit', cb

# We're going to give the bork task instance a different name, to avoid
# overlapping Cakefile.task.
bork_task = bork()


task 'build', 'build all', ->
  invoke 'build:lib'
  invoke 'build:test'
  bork_task.start()

task 'build:lib', 'build lib', ->
  bork_task.link (done) ->
    console.log 'build lib start'
    exec COFFEE_BIN, ['-co', './build/lib', './lib'], ->
        console.log 'build lib done'
        done()

task 'build:test', 'build test', ->
  bork_task.link (done) ->
    console.log 'build test start'
    exec COFFEE_BIN, ['-co', './build/test', './test'], ->
        console.log 'build test done'
        done()

task 'test', 'build test, then run it', ->
  invoke 'build:test'
  invoke 'test:nobuild'
  bork_task.start()

task 'test:all', 'build all, and run the tests', ->
  invoke 'build:lib'
  invoke 'build:test'
  invoke 'test:nobuild'
  bork_task.start()

task 'test:nobuild', 'just run the tests, don\'t build anything', ->
  bork_task.seq (done) ->
    console.log 'test start'
    exec MOCHA_BIN, ['./test'], ->
        console.log 'test done'
        done()

task 'prepublish', 'Build all, test all. Designed to work before `npm publish`', ->
  invoke 'build:lib'
  invoke 'build:test'
  invoke 'test:nobuild'
  bork_task.start()
