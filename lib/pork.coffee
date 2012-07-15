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

# (source, recursive, callback, stream) -> undefined
#
# Params:
#   source: The path to the file/directory to list.
#   recursive: Truthy if you want it to recursively list.
#   callback: Called when the full list (including any nested listings) are
#     finished. The callback is given the arguments `err, results` where
#     `err` is an error object (or null) and `results` is a list of results,
#     populated with the same data as stream is given: `[[base, rel,
#     file, stats], [base, rel, file, stats]]` and etc.
#   stream: Called on each file match. Each call is given `base, rel,
#     file, stats`.
#
# Desc:
#   List files in a directory recursively or not. Files found are streamed as
#   well as given to the callback. This is just shorthand for calling
#   `relative_list` and `recursive_list`.
list = (source='', recursive=false, callback, stream) ->
  
  if recursive
    recursive_list source, '', '', callback, stream
  else
    relative_list source, '', '', callback, stream

move = ->
  throw new Error 'Not Implemented'

read = ->
  throw new Error 'Not Implemented'

# (base, rel, file, callback, stream) -> undefined
#
# Params:
#   base: The base path. If this is a directory, it is perserved and can be
#     nested for recursive callbacks.. though, i'm not sure why you would
#     since this is already recursive.
#   rel: The state of the recursive depth is stored in the rel var.
#   file: The current file.
#   callback: Called when all listing is done. See `list` documentation for
#     callback formatting.
#   stream: Called on each file/dir/etc match. See `list` documentation for
#     stream formatting.
#
# Desc:
#   A function that recursively calls `relative_list()`. Like `relative_list`,
#   this function has the notable ability to preserve a base directory,
#   relative directory, and file when iterating through the directory.
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

# (base, rel, file, callback, stream) -> undefined
#
# Params:
#   base: The base path. If this is a directory, it is perserved and can be
#     nested for recursive callbacks.. though, i'm not sure why you would
#     since this is already recursive.
#   rel: The state of the recursive depth is stored in the rel var.
#   file: The current file.
#   callback: Called when all listing is done. See `list` documentation for
#     callback formatting.
#   stream: Called on each file/dir/etc match. See `list` documentation for
#     stream formatting.
#
# Desc:
#   List a single directories (or file..) contents. Notably, with the ability
#   to preserve a base directory, relative directory, and file when iterating
#   through the directory.
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
