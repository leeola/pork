#
# # Pork File & Path Utilities
# 
# 
fs = require 'fs'
path = require 'path'




# ## Home
# 
# Attempt to find the systems home path.
home = ->
  switch process.platform
    when 'win32' then process.env.USERPROFILE
    when 'linux' then process.env.HOME
    else process.env.HOME or process.env.USERPROFILE


# ## Separator
# 
# Find the system separator. This is simply a legacy fix for multiple
# versions of 
sep = -> if path.sep then path.sep else path.join('a', 'b')[1]




exports.__defineGetter__ 'home', home
exports.__defineGetter__ 'sep', sep
