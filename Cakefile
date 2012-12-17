# 
# # Pork Cakefile
# 
# 
path = require 'path'
{spawn} = require 'child_process'
pork = require './lib'




COFFEE_BIN = path.join 'node_modules', 'coffee-script', 'bin', 'coffee'




# ## Streaming Exec
# 
# A simple process launcher that streams output to the given callback. The
# arguments are the path of the executable, a list of arguments, and a
# callback.
exec = (cmd, args=[], cb=->) ->
  bin = spawn cmd, args
  bin.stdout.on 'data', (data) ->
    process.stdout.write data
  bin.stderr.on 'data', (data) ->
    process.stderr.write data
  bin.on 'exit', cb


# ## Error Handler
# 
# A simple error handler. If an error is provided, this prints the output
# to console and exits the process with a failure code.
err_handler = (err) ->
  if err?
    console.log "Cake Error: #{err.message}"
    process.exit 0


# ## Compile and Copy Sources
# 
# Remove the build directory, and then compile or copy the supplied list
# of sources. Any .coffee file is compiled, and non-.coffee file is copied.
compile = (sources) ->
  pork.remove './build', depth: 0, (err) ->
    if err? and err.message isnt "ENOENT, stat 'build'"
      return err_handler err
    pork.list SOURCE_LIST, depth: 0, err_handler, (file, info) ->
      if info.isfile
        if file[-7..] is '.coffee'
          dir = path.dirname file
          console.log "Compiling file.. '#{file}' to "+
            "'./build/#{dir}/#{path.basename file[0..-8]}.js'"
          exec COFFEE_BIN, ['-co', "./build/#{dir}", file]
        else
          console.log "Copying file.. '#{file}' to './build/#{file}'"
          pork.copy file, "./build/#{file}"


task 'build', 'build all', ->
  compile ['./lib', './test']

task 'prepublish', 'Build all, test all. Designed to work before `npm publish`', ->
  compile ['./lib', './test']
