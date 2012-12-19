#
# # Test Index
# 
# Our testing index.
dork = require 'dork'




#Currently `Coffee` ignores dot files, so we aren't using this. However,
#once this library hits 0.0.1, we will re-enable this since we'll be using
#Pork to locate the files, instead of Coffee.
#exports['.options'] = require './.options'
exports.options = require './options'
exports.pork = require './pork'
if require.main is module then dork.run()