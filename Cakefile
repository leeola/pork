# 
# # Pork Cakefile
# 
# 
path = require 'path'
{spawn} = require 'child_process'
pork = require './lib'




COFFEE_BIN = path.join 'node_modules', 'coffee-script', 'bin', 'coffee'
DORK_BIN = path.join 'node_modules', 'dork', 'build', 'bin', 'dork'




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


# ## Compile and Copy Sources
# 
# Remove the build directory, and then compile or copy the supplied list
# of sources. Any .coffee file is compiled, and non-.coffee file is copied.
compile = (sources, callback) ->
  
  source_bork = bork = (require 'bork')()
  
  bork = bork.seq (next) ->
    pork.remove './build', depth: 0, (err) ->
      if err? and err.message isnt "ENOENT, stat 'build'"
        console.log "Cake Error: #{err.message}"
        process.exit 0
        return
      next()
  
  bork = bork.seq (nextz) ->
    pork.list sources, depth: 0,
      ((err) ->
        if err?
          console.log "Cake Error: #{err.message}"
          process.exit 0
          return
        nextz()
      ),
      (file, info) ->
        if info.isfile
          bork.link (next) ->
            if file[-7..] is '.coffee'
              dir = path.dirname file
              exec COFFEE_BIN, ['-co', "./build/#{dir}", file], ->
                console.log "Compiled file.. '#{file}' to "+
                  "'./build/#{dir}/#{path.basename file[0..-8]}.js'"
                next()
            else
              pork.copy file, "./build/#{file}", (err) ->
                console.log "Copied file.. '#{file}' to './build/#{file}'"
                if err?
                  console.log "Cake Error: #{err.message}"
                  process.exit 0
                  return
                next()
  
  source_bork.start()


task 'build', 'build all', ->
  compile ['./lib', './test']

task 'prepublish', 'Build all, test all. Designed to work before `npm publish`', ->
  compile ['./lib', './test']
