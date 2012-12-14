#
# # Pork File & Path Utilities
# 
# 
fs = require 'fs'
path = require 'path'




# ## Copy
# 
# Copy the given path to the output directory.
copy = (fin, out, opts={}, callback=->) ->
  if opts instanceof Function
    stream_callback = callback
    callback = opts
    opts = {}
  opts.depth ?= 0
  opts.overwrite ?= true
  opts.merge ?= true
  
  #Some basic state trackers. Not pretty, but they work.
  running = true
  listing = true
  writing = 0
  
  fin_info = undefined
  
  done_check = ->
    if running and writing <= 0 and not listing
      callback null
  
  cb = () ->
    listing = false
    done_check()
  
  scb = (err, in_path, info) ->
    if not running then return
    if err?
      running = false
      callback err
      return
    writing += 1
    
    #We need to get the info about `fin` to figure out if it is
    #a file or dir. So, we're assuming that our first match is the proper
    #fin. If this turns out to not always be true, no biggie, we can just
    #pull the info before we start listing.
    if not fin_info?
      fin_info = info
    
    if not opts.merge
      #If the user specified to not merge, we don't care if fin is
      #a dir or file, we just put fin in the out.
      out_path = path.join out, in_path
    else if not fin_info.isfile
      #If fin is a dir, and the user has specified to merge, remove the
      #first dir provided on the fin, so that we can merge the contents of
      #dir into out.
      dirs = in_path.split sep()
      dirs[0] = out
      out_path = dirs.join sep()
    else
      out_path = out
    
    if info.isfile
      make_directory (path.dirname out_path), (err) ->
        if err? and err.message isnt 'Directory already exists'
          running = false
          callback err
          return
        read_file in_path, (err, data) ->
          if err?
            running = false
            callback err
            return
          write_file out_path, data, overwrite: opts.overwrite, (err) ->
            if err?
              running = false
              callback err
              return
            writing -= 1
            done_check()
    else
      writing -= 1
      done_check()
  
  list fin, depth: opts.depth, cb, scb


# ## Exists
# 
# Check whether or not the given path exists. This is exactly the same
# as `fs.exists`, except that it checks for the existance of `fs.exists` and
# swaps in the older, deprecated `path.exists` if needed.
exists = if fs.exists? then fs.exists else path.exists


# ## Exists Sync
# 
# Check whether or not the given path exists. This is exactly the same
# as `fs.existsSync`, except that it checks for the existance of `fs.existsSync`
# and swaps in the older, deprecated `path.existsSync` if needed.
exists_sync = if fs.existsSync? then fs.existsSync else path.existsSync


# ## Exists Cascade
# 
# Check for the existance of the given path. If it does not exist, it
# will traverse up the chain until it finds a path that exists.
# 
# The callback will be given a boolean first argument, a list of
# `[[bool, 'dir/file'], [bool, 'dir']]` for each dir that the function
# checks, and a final bool value if the cascade was able to find any dir that
# exists.
exists_cascade = (file, callback=->) ->
  cwd = file
  results = []
  #The callback we give to exists
  exists_cb = (result) ->
    results.push [result, cwd]
    if result
      if results.length is 1
        callback true, results, true
      else
        callback false, results, true
    else
      cwd = path.dirname cwd
      #If we're at the relative root, but the caller did not actually define
      #a relative root, callback and end.
      if cwd is '.' and file[..1] isnt ".#{sep()}"
        callback false, results, false
      else
        exists cwd, exists_cb
  exists file, exists_cb


# ## User Home
# 
# Attempt to find the systems home path.
home = ->
  switch process.platform
    when 'win32' then process.env.USERPROFILE
    when 'linux' then process.env.HOME
    else process.env.HOME or process.env.USERPROFILE


# ## List Files & Directories
# 
# List all of the files in the given path, with optional recursive depth. The
# format is `path, options, callback, streaming_callback`, where `options`
# supports the following options..
# - depth: The recursive depth. Default is `1`, and `0` means infinite.
# 
# The callback format is `error, path, info`. Where `error` is the
# error object *(null if none)*, `path` is the combined path
# *(`/foo/bar/baz/zam`)*, `info` is an object containing information 
# gathered during the list process. Provided simply because it was
# generated, and may be useful. The format of this object is as follows..
# 
#     {
#       path: '/foo/bar/baz/zam',
#       base: '/foo/bar',
#       rel: 'baz',
#       file: 'zam',
#       isfile: true,
#       stat: stat
#     }
# 
list = (base, opts={}, callback=(->), streaming_callback=->) ->
  if opts instanceof Function
    streaming_callback = callback
    callback = opts
    opts = {}
  opts.depth ?= 1
  rel = ''
  
  # ### Format Paths
  # 
  # Our recursive function `rlist` only tracks relative and file paths,
  # since it has no need to track the base *(and only complicates things)*.
  # 
  fmt = (rel, file) ->
    if rel is base
      return base: base, rel: '', file: file
    else if base is path.join rel, file
      return base: base, rel: '', file: ''
    else
      return base: base, rel: (subtract base, rel), file: file
  
  # ### Recursively Stat
  # 
  # 
  rlist = (rel, file, depth, cb) ->
    src = path.join rel, file
    
    fs.stat src, (err, stat) ->
      if err?
        streaming_callback err, null
        cb err, null
        return
      
      #Make our info, and callback to the stream
      info = fmt rel, file
      info.path = src
      info.isfile = stat.isFile()
      info.stat = stat
      streaming_callback null, src, info
      
      #rlist is listing a file
      if info.isfile
        cb null, [info]
        return
      #rlist is listing a dir, but we don't want to go into it
      else if depth >= opts.depth and opts.depth > 0
        cb null, [info]
        return
      #rlist is listing a dir, and we want to go into it
      else
        fs.readdir src, (err, files) ->
          rel = src
          cb_count = 0
          running = true
          file_infos = [info]
          for file in files
            rlist rel, file, depth+1, (err, fi) ->
              if not running then return
              if err?
                streaming_callback err, null
                cb err, null
                running = false
                return
              cb_count += 1
              file_infos = file_infos.concat fi
              if cb_count >= files.length
                cb null, file_infos
                return
  
  #Now run our rlist on the base.
  rlist base, '', 0, (err, file_infos) ->
    callback err, file_infos


# ## Make Directory
# 
# Make a directory, with an optional recursive option.
make_directory = (dir, opts={}, callback=->) ->
  if opts instanceof Function
    callback = opts
    opts = {}
  opts.cascade ?= true
  opts.mode ?= undefined
  
  if opts.cascade
    #Take a cascade list and create all directories that are missing.
    mkdir_cascade = (cascade) ->
      cascade_item = cascade.pop()
      if not cascade_item? then return callback null
      [dir_exists, dir] = cascade_item
      
      #If the dir exists, that simply means the root dir existed and
      #we want to ignore it.
      if dir_exists then return mkdir_cascade cascade
      
      fs.mkdir dir, opts.mode, (err) ->
        if err?
          if err.message[0...13] is 'EEXIST, mkdir'
            return callback new Error 'Directory already exists'
          return callback err
        mkdir_cascade cascade
    
    #Get a cascade of existing/not directories.
    exists_cascade dir, (exists, cascade, root_exists) ->
      if exists
        callback new Error 'Directory already exists'
      else
        mkdir_cascade cascade
    
  else
    fs.mkdir dir, opts.mode, (err) ->
      if err?
        if err.message[0...13] is 'EEXIST, mkdir'
          return callback new Error 'Directory already exists'
        return callback err
      callback null


# ## Read File
# 
# This is simply a pointer to `fs.readFile`, because i actually like it.
read_file = fs.readFile


# ## Separator Character
# 
# Find the system separator. This is simply a legacy fix for multiple
# versions of 
sep = -> if path.sep then path.sep else path.join('a', 'b')[1]


# ## Subtract Path
# 
# Subtract the one path from another, from the beginning.
subtract = (a, b) ->
  #Split the paths, but preserve the root sep if it exists
  split = (path) ->
    r = path.split sep()
    if r[0] is ''
      r.splice 0, 1
      r[0] = sep() + r[0]
    return r
  a = split a
  b = split b
  for j, i in a
    if j isnt b[i]
      break
  return b[i..].join sep()


# ## Write File
# 
# Write a file with the given data.
write_file = (file, data, opts, callback=->) ->
  if opts instanceof Function
    callback = opts
    opts = {}
  opts.encoding ?= undefined
  opts.parents ?= true
  
  dir = path.dirname file
  exists dir, (dir_exists) ->
    if dir_exists
      fs.writeFile file, data, opts.encoding, callback
    else if opts.parents
      make_directory dir, cascade: true, (err) ->
        if err? then return callback err
        fs.writeFile file, data, opts.encoding, callback
    else
      callback new Error 'Directory does not exist'




exports.copy = copy
exports.exists = exists
exports.exists_cascade = exists_cascade
exports.exists_sync = exists_sync
exports.__defineGetter__ 'home', home
exports.list = list
exports.make_directory = make_directory
exports.__defineGetter__ 'sep', sep
exports.read_file = read_file
exports.subtract = subtract
exports.write_file = write_file