#
# lib/pork.coffee
#
# Copyright (c) 2012 Lee Olayvar <leeolayvar@gmail.com>
# MIT Licensed
#


# () -> string
#
# Desc:
#   Attempt to find the host systems home path.
find_home = ->
  switch process.platform
    when 'win32' then process.env.USERPROFILE
    when 'linux' then process.env.HOME
    else process.env.HOME or process.env.USERPROFILE


# A file utility class. Chock full of handy features!
class Pork
  # () - >
  #
  # Params:
  #
  # Desc:
  #   Create a Pork instance.
  construction: (options={
      base: process.cwd()
      home: find_home()
      }) ->
    @_base = options.base
    @_home = options.home


# () -> undefined
# 
# Desc:
#   Create a new Pork instance.
exports.create = -> new Pork()
exports.Pork = Pork