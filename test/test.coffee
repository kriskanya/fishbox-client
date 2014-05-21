fb = require '../src/index'

# fb.get_email('forgot')
# .then (message) ->
#   console.log message
#
#  # fb.get_link('TEST', contains_text, 10)
#  # .then (message) ->
#  #   console.log message


fb.get_link_poll('forgot', 'NextGxDx Password Reset', 'reset')
.then (message) ->
  console.log message
, (error) ->
  console.log erro
