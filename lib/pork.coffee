#
# # Pork File & Path Utilities
# 
# 
fs = require 'fs'
path = require 'path'




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




exports.exists = exists
exports.exists_cascade = exists_cascade
exports.exists_sync = exists_sync
exports.__defineGetter__ 'home', home
exports.list = list
exports.__defineGetter__ 'sep', sep
exports.subtract = subtract
