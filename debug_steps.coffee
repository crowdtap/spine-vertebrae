sharedSteps = module.exports = ->
  @World = require("../support/world").World

  @Given /^I enable debugging$/, (next) ->
    @browser.debug = true
    next()

  @Then /^show me the current page info$/, (next) ->
    @browser.dump()

    @browser.wait ->
      next()

  @Then /^evaluate (.+)$/, (js, next) ->
    console.log @browser.evaluate(js)

    @browser.wait ->
      next()
