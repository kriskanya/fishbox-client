Promise = require 'bluebird'
qs = require 'querystring'
q = require 'q'
request = require 'request'
_ = require 'lodash'
cheerio = require 'cheerio'
HTTP = require "q-io/http"

a = undefined
# fb.set_fish_box('http://fishbox.nxtgd.net')

FISH_BOX = 'DEFAULT_URL'

set_fish_box = (fish_box) ->
  FISH_BOX = fish_box

get_fish_box = ->
  FISH_BOX

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

get_content = (handle, subject, contains_text) ->
  gn.set_fish_box('http://fishbox.nxtgd.net')

  body_text = q.defer()
  gn.get_email(handle).then (data) ->
    mailbox = data
    console.log(mailbox[0].html)
    console.log(mailbox.length, mailbox[0].subject)

    if mailbox.length > 0 && mailbox[0].subject is subject
      return mailbox[0].html
    else
      body_text.reject 'no_matching_email'
  .then (html) ->
    $ = cheerio.load(html)
    # console.log $("body:contains(#{contains_text})").text()
    body_text.resolve $("body:contains(#{contains_text})").text()

  , (error) ->
    body_text.reject error

  return body_text.promise

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

  if attempts < 10
    get_link(handle, subject, contains_text)
    .then (email) ->
      link.resolve email
    , (error) ->
      if error is 'no_matching_email' || error is '404'
        setTimeout ->
          link.resolve get_link_poll(handle, subject, contains_text, attempts)
        , 6000
      else
        link.reject error
  else
    link.reject 'max_email_fetch_attempts_reached'

  return link.promise

clear_inbox = (handle) ->
  HTTP.request
    url: "#{FISH_BOX}/#{handle}"
    method: 'DELETE'
  .then (rsp) ->
    rsp.body.read()
  .then (data) ->
    data.toString 'utf-8'

gn = {
  get_content
  get_email
  get_link_poll
  set_fish_box
  get_fish_box
  clear_inbox
}

module.exports = gn
