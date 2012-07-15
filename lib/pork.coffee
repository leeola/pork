#
# lib/pork.coffee
#
# Copyright (c) 2012 Lee Olayvar <leeolayvar@gmail.com>
# MIT Licensed
#
fs = require 'fs'
path = require 'path'

# Some direct references to common objects.
path_join = path.join



copy = ->
  throw new Error 'Not Implemented'

# () -> string
#
# Desc:
#   Attempt to find the host systems home path.
home = ->
  switch process.platform
    when 'win32' then process.env.USERPROFILE
    when 'linux' then process.env.HOME
    else process.env.HOME or process.env.USERPROFILE

# () ->
list = (source='', recursive=false, callback, stream) ->
  non_recursive_callback = (err, results) ->
    new_results = []
    for [base, rel, file, stats] in results
      base = path_join base, rel
      new_results.push [base, file, stats]
    callback err, new_results
  
  non_recursive_stream = (base, rel, file, stats) ->
    base = path_join base, rel
    stream base, file, stats
  
  if recursive
    recursive_list source, '', '', callback, stream
  else
    relative_list source, '', '', non_recursive_callback, non_recursive_stream

move = ->
  throw new Error 'Not Implemented'

read = ->
  throw new Error 'Not Implemented'

# () ->
recursive_list = (base, rel, file, callback, stream) ->
  results = []
  depth = 0
  
  single_callback = (err, single_results) ->
    results.push single_results...
    if depth is 0
      callback null, results
    else
      depth--
  
  single_stream = (base, rel, file, stats) ->
    stream base, rel, file, stats
    if stats.isDirectory()
      depth++
      relative_list base, rel, file, single_callback, single_stream
  
  relative_list base, rel, file, single_callback, single_stream

# () ->
relative_list = (base, rel, file, callback, stream) ->
  source = path_join base, rel, file
  
  fs.stat source, (err, stats) ->
    if err?
      callback err
      return
    
    if stats.isFile()
      if file is ''
        base = path.dirname source
        file = path.basename source
      stream base, rel, file, stats
      callback null, [[base, rel, file, stats]]
    else
      file_count = 0
      file_results = []
      
      fs.readdir source, (err, files) ->
        if err
          callback err
        
        total_files = files.length
        if total_files is 0
          callback null, []
        else
          rel = path_join rel, file
        
        stats_closure = (base, rel, file) ->
          source = path.join(base, rel, file)
          fs.stat source, (err, stats) ->
            if err
              callback err
            
            stream base, rel, file, stats
            
            file_results.push [base, rel, file, stats]
            file_count++
            if file_count is total_files
              callback null, file_results
        
        for file in files
          stats_closure base, rel, file

remove = ->
  throw new Error 'Not Implemented'

write = ->


exports.copy = copy
exports.home = home
exports.list = list
exports.recursive_list = recursive_list
exports.relative_list = relative_list
exports.remove = remove
