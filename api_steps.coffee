Moment = require 'moment'

apiSteps = module.exports = ->

  @After (next) ->
    @browser.wait =>
      @nock.done() # Assert all mocks have cleared
      next()

  @Given /^the API returns the following JSON response for ([^:]+):$/, (pathMatcher, jsonString, next) ->
    path = @selectorFor(pathMatcher)
    @nock.get(path).reply(200, JSON.parse(jsonString))
    next()

  @Given /^the API returns a 404 for (.+)$/, (pathMatcher, next) ->
    path = @selectorFor(pathMatcher)
    @nock.get(path).reply(404, [])
    next()

  @Given /^the API doesn't return for "([^"]*)"$/, (url, next) ->
    @nock.get(url).reply(404, [])
    next()

  @Given /^the API accepts (GET|POST) requests? (?:for|to) "([^"]*)"(?: and responds with:)?$/, (requestType, path, body, next) ->
    unless typeof next == 'function'
      next = body
      body = ""

    if requestType == 'POST'
      @nock.filteringRequestBody( () -> return '').post(path).reply(200, body)
    else
      @nock.get(path).reply(200, body)

    next()

  @Then /^I should (not )?have made a GET request for (.*)$/, (negation, pathMatcher, next) ->
    path = @selectorFor(pathMatcher)
    actual_request_params = @recorder.lastGetByPath(path)

    if negation
      actual_request_params.should.eql false, "Expected a request not to have been made to '#{path}'"
    else
      actual_request_params.should.not.eql false, "Expected a request to have been made to '#{path}'"

    next()

  @Then /^I should have made a POST request for (.*) with:$/, (pathMatcher, string, next) ->
    path = @selectorFor(pathMatcher)
    actual_request_params = @recorder.lastPostByPath(path).params
    delete actual_request_params.id

    expected_request_params = JSON.parse(string)

    actual_request_params.should.eql expected_request_params , "Expected Request did not match Actual Request"

    next()

  @Given /^the API returns the following brand actions json response:$/, (table, next) ->
    now = Date.now() / 1000
    actions = []
    rows = table.hashes()

    for row in rows
      if row.created_at
        timestamp = @strtotime(row.created_at, now) * 1000
        row.created_at = Moment(timestamp).format("MM/DD/YYYY")
        res = @Factory(row.type, row)
        res.options = eval(row.options)
        actions.push res

    @nock.get("/api/v1/clients/brands/#{@brand_id}/targetable_brand_actions").reply(201, actions)
    next()
