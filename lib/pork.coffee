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

# (path, [callback]) -> undefined
#
# Params:
#   path: The path to check existance of.
#   callback: Optional. The callback called with the truthy answer.
#
# Desc:
#   Just a local reference to fs.exists.
exists = if fs.exists? then fs.exists else path.exists

# (file, [callback]) ->
#
# Params:
#   file: The path to cascade check existance of.
#   callback: Optional. The callback called with the cascade data.
#
# Desc:
#   Check for existance of the given file or directory. If it does not exist,
#   the function will traverse up the given directory structure one level and
#   check if that exists. It will keep doing this until an existance is found,
#   or until the given path has been traversed as far as possible.
#
#   For example, `fake/dir` will check for existance of `./fake/dir`, and then
#   `./fake` and then fail. It will *not* check `./` because that was not
#   supplied in the file argument. Note that `./` was added in this example
#   because `fake/dir` is a relative directory to begin with.. it just lacks
#   the explicit definition of the relative base.
#
#   The callback data for this will be the following:
#     false,
#     [
#       [false, 'fake/dir']
#       [false, 'fake']
#     ]
#
#   On the other hand, if the file argument was `./fake/dir` it will check
#   `./fake/dir`, then `./fake` then it will succeed with the final check,
#   `./`.
#
#   The callback data for this will be the following:
#     true,
#     [
#       [false, './fake/dir']
#       [false, './fake']
#       [true, './']
#     ]
exists_cascade = (file, callback=->) ->
  # The cwd being cascaded upwards.
  cwd = file
  # Each upward cascade result is stored here.
  results = []
  
  exists_callback = (exist_result) ->
    # Push our results.
    results.push [exist_result, cwd]
    if exist_result
      # If it does exist, callback and we're done.
      callback true, results
    else
      # If it does not exist, we need to go up a directory and try again.
      cwd = path.dirname cwd
      if cwd is '.' and file[...2] isnt '.'+sep()
        # If we're at the relative root, and the caller did not define a
        # relative root, callback and end.
        callback false, results
      else
        # Otherwise try again.
        exists cwd, exists_callback
  # Start our exists check.
  exists file, exists_callback

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
  # We're going to save a few cycles and call relative vs recursive, if we
  # can.
  if recursive
    recursive_list source, '', '', callback, stream
  else
    relative_list source, '', '', callback, stream

move = ->
  throw new Error 'Not Implemented'

# (file, [encoding], [callback]) -> undefined
#
# Desc:
#   A reference to `fs.readFile`.
read_file = fs.readFile

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
  # This is how recursively nested we are into directories.
  depth = 0
  
  # Push the results from the single list, and if we're not nested (depth > 0)
  # then call back.
  single_callback = (err, single_results) ->
    results.push single_results...
    if depth is 0
      callback null, results
    else
      depth--
  
  # Pass the stream event off to the stream function. If the file is a
  # directory, list it's contents and increment the depth.
  single_stream = (base, rel, file, stats) ->
    stream base, rel, file, stats
    if stats.isDirectory()
      depth++
      relative_list base, rel, file, single_callback, single_stream
  
  # Start off the chain by calling relative_list.
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
  # The file/directory we are listing.
  source = path_join base, rel, file
  
  # Get the stat, so we know if it's a dir or file.
  fs.stat source, (err, stats) ->
    # If err, bail.
    if err?
      callback err
      return
    
    if stats.isFile()
      # If the source is a file, we can just return it.. since we don't have
      # anything more to list.
      
      if file is ''
        # Since the caller supplied a file, but not in the file var, we
        # need to grab the file and remove it from whichever var it came in
        # on.
        
        # Grab our file name.
        file = path.basename source
        
        # Based on the file we got, check the `rel` and `base` vars to see
        # which one the file name came from.
        if rel[-(file.length)...] is file
          rel = rel[..(file.length+1)]
        else
          base = base[..(file.length+1)]
      
      # Call stream, and callback.
      stream base, rel, file, stats
      callback null, [[base, rel, file, stats]]
      return
    else
      # A counter for how many files we have returned.
      file_count = 0
      # Our collected results, given to callback.
      file_results = []
      
      # Read the dir.
      fs.readdir source, (err, files) ->
        # Bail, if err.
        if err
          callback err
          return
        
        # A local assignment, so we're not constantly accessing files.length
        total_files = files.length
        if total_files is 0
          # If we have no files, callback and return.
          callback null, []
          return
        else
          rel = path_join rel, file
          if rel is '.'
            rel = ''
        
        # Our closure function, so we can loop through the files and call
        # stat on each file.
        stats_closure = (base, rel, file) ->
          # Get our given source and run fs.stat
          source = path.join(base, rel, file)
          fs.stat source, (err, stats) ->
            if err
              callback err
            
            stream base, rel, file, stats
            
            file_results.push [base, rel, file, stats]
            
            # Increase our count, and then check the count to the total.
            # callback with the results.
            file_count++
            if file_count is total_files
              callback null, file_results
        
        # Call our closure with the file name.
        for file in files
          stats_closure base, rel, file

remove = ->
  throw new Error 'Not Implemented'

# () -> string
#
# Desc:
#   Calculate the path separator for the host os. Note that if available,
#   this just uses `path.sep`, but that is a new feature to 0.8.
sep = ->
  if path.sep then path.sep else path.join('a', 'b')[1]

# (file, data, [encoding], [callback]) -> undefined
#
# Params:
#   file: The filename to write.
#   data: The contents of the file.
#   encoding: Optional. The encoding of the file.
#   callback: Optional. Called when the file has finished writing, or after
#     any errors.
#
# Desc:
#   Write a file to disk. This is the same as `fs.writeFile` with the notable
#   feature that if the directory(ies) being written does not exist, they
#   will be created.
write_file = (file, data, encoding, callback=->) ->
  dir = path.dirname file
  
  # Check if the directory exists. If it doesn't, call `make_directory` then
  # `write_file`
  exists dir, (dir_exists) ->
    if not dir_exists
      make_directory dir, (err) ->
        if err
          throw err
        fs.writeFile file, data, encoding, callback
    else
      fs.writeFile file, data, encoding, callback



exports.copy = copy
exports.exists = exists
exports.exists_cascade = exists_cascade
exports.home = home
exports.list = list
exports.recursive_list = recursive_list
exports.relative_list = relative_list
exports.remove = remove
exports.sep = sep
exports.write_file = write_file
