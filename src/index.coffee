qs = require 'querystring'
q = require 'q'
request = require 'request'
_ = require 'lodash'
cheerio = require 'cheerio'

FISH_BOX = 'DEFAULT_URL'

set_fish_box = (fish_box) ->
  FISH_BOX = fish_box

make_request = (url) ->

  deferred = q.defer()

  request(url, (error, response, body) ->
    if response.statusCode isnt 200
      deferred.reject response.statusCode
    else
      deferred.resolve JSON.parse(body)
  )

  return deferred.promise

# gets a new email address
get_email = (handle) ->

  return make_request FISH_BOX + "/#{handle}"

# helper functions
get_link = (handle, subject, contains_text) ->

  link_text = q.defer()

  gn.get_email(handle).then (data) ->
    mailbox = data

    if mailbox.length > 0 && mailbox[0].subject is subject
      return mailbox[0].html
    else
      link_text.reject 'no_matching_email'
  .then (html) ->
    $ = cheerio.load(html)
    link_text.resolve $("a:contains(#{contains_text})").text()

  , (error) ->
    link_text.reject error

  return link_text.promise

get_link_poll = (handle, subject, contains_text, attempts=0) ->

  link = q.defer()

  attempts = attempts + 1

  if attempts < 6
    get_link(handle, subject, contains_text)
    .then (email) ->
      link.resolve email
    , (error) ->
      if error is 'no_matching_email' || error is '404'
        setTimeout ->
          link.resolve get_link_poll(handle, subject, contains_text, attempts)
        , 4000
      else
        link.reject error
  else
    link.reject 'max_email_fetch_attempts_reached'

  return link.promise

gn = {
  get_email
  get_link_poll
  set_fish_box
}

module.exports = gn
