should = require 'should'

sharedSteps = module.exports = ->
  @World = require("../support/world").World

  @Given /^I am on the home ?page$/, (next) ->
    @visit "/index.html", next

  @Given /^I am on the home ?page with the hash "([^"]*)"$/, (text, next) ->
    @visit "/index.html", (err, browser, status) ->
      browser.location = "##{text}"
      browser.wait (e, browser) ->
        next()

  @Given /^the maximum targeted action count is (\d+)$/, (count, next) ->
    @browser.max_targeted_action_count = count

    next()

  @Then /^the url hash should be "([^"]*)"$/, (text, next) ->
    @browser.location._url.hash.should.eql text, "window hash"
    next()

  @Then /^I should (not )?see (.+)$/, (negation, namedElement, next) ->
    selector = @selectorFor(namedElement)
    element = @browser.queryAll(selector)

    if negation
      element.length.should.eql 0, "Number of elements with selector #{selector}"
    else
      element.length.should.eql 1, "Number of elements with selector #{selector}"

    next()

  @Then /^I should see (\d+) ([^:]+)$/, (number, namedElement, next) ->
    selector = @selectorFor(namedElement)
    element = @browser.queryAll(selector)

    element.length.should.eql parseInt(number), "Number of elements with selector #{selector}"

    next()

  @Then /^I should see the following brand actions within (.*):$/, (namedElement, table, next) ->
    container_selector = @selectorFor(namedElement)

    rows = table.hashes()
    for row in rows
      count = row.count
      brand_action_selector = @selectorFor(row.type)
      selector = "#{container_selector} #{brand_action_selector}"
      element = @browser.queryAll(selector)
      element.length.should.eql parseInt(count), "Number of elements with selector #{selector}"

    next()

  @Then /^(.*) should be (\d+) characters long$/, (namedElement, length, next) ->
    selector = @selectorFor(namedElement)
    element = @browser.query(selector)
    should.exist element, "couldn't locate element with selector '#{namedElement}'"

    text = @browser.text(selector)
    text.length.should.equal parseInt(length), "Expected '#{text}' to be #{length} characters long"

    next()

  @When /^I press (.*)$/, (button, next) ->
    if /^"([^"]*)"$/.test(button)
      buttonSelector = "input[value=#{button}]"
    else
      buttonSelector = @selectorFor(button)

    @browser.pressButton buttonSelector, (error, browser, event) ->
      next()

  @When /^I click (.*)$/, (link, next) ->
    if /^"([^"]*)"$/.test(link)
      linkSelector = "a:contains(#{link})"
    else
      linkSelector = @selectorFor(link)

    @browser.clickLink linkSelector, (error, browser, event) ->
      throw error if error
      next()

  @When /^I check (.*)$/, (checkbox, next) ->
    if /^"([^"]*)"$/.test(checkbox)
      checkboxSelector = "input[data-value=#{checkbox}]"
    else
      checkboxSelector = @selectorFor(checkbox)

    @browser.check checkboxSelector, (error, browser, event) ->
      next()

  @Then /^(.*) should be (visible|hidden)$/, (namedElement, visibility, next) ->
    selector = @selectorFor(namedElement)

    elementDisplay = @browser.evaluate("$(\"#{selector}\").css('display')")
    elementVisibility = @browser.evaluate("$(\"#{selector}\").css('visibility')")

    if visibility == "visible"
      (elementDisplay != "none" && elementVisibility == "visible").should.eql(true, "Element not visible")
    else
      (elementDisplay == "none" || elementVisibility == "hidden").should.eql(true, "Element not hidden")

    next()

  @Then /^(.*) should (not )?exist$/, (namedElement, notExist, next) ->
    selector = @selectorFor(namedElement)
    element  = @browser.query(selector)

    if notExist
      should.not.exist(element, "Found #{selector}")
    else
      should.exist(element, "Did not find #{selector}")

    next()

  @Given /^I will (confirm|deny) the "([^"]*)" prompt$/, (response, message, next) ->
    if response == "confirm"
      @browser.onconfirm(message, true)
    else
      @browser.onconfirm(message, false)

    next()

  @Then /^show me the page$/, (next) ->
    @browser.viewInBrowser()
    @browser.wait =>
      console.log "\nBrowser Errors:", @browser.errors
      console.log @browser.html()

    next()

  @Then /^show me the contents of (.*)$/, (namedElement, next) ->
    @browser.wait =>
      selector   = @selectorFor(namedElement)
      htmlString = @browser.html(selector)

      console.log "Errors: #{@browser.errors}"
      console.log "\nHTML Contents of #{selector}:"
      console.log htmlString

    next()

  @Then /^I wait (\d*) seconds?$/, (seconds, next) ->
    seconds = 1000*parseInt(seconds)
    @browser.wait seconds,  (e, obj) ->
      next()

  @When /^I fill in (.+) with "([^"]*)"$/, (namedElement, text, next) ->
    selector = @selectorFor(namedElement)
    element = @browser.query(selector)
    should.exist(element, "couldn't find '#{selector}'")

    @browser.fill(selector, text)
    @browser.fire('keyup', element)

    next()

  @When /^I empty (.+)$/, (namedElement, next) ->
    selector = @selectorFor(namedElement)
    element = @browser.query(selector)
    should.exist(element, "couldn't find '#{selector}'")

    @browser.evaluate("$('#{selector}').html('')")
    @browser.fire('keyup', element, next)

  @Then /^(.*) should be (enabled|disabled)$/, (namedElement, state, next) ->
    selector = @selectorFor(namedElement)
    element = @browser.query(selector)
    should.exist(element, "couldn't find '#{selector}'")

    stateElement = @browser.query("#{selector}:disabled")

    if state == "disabled"
      should.exist(stateElement, "Found '#{selector}' but it was not #{state}")
    else
      should.not.exist(stateElement, "Found '#{selector}' but it was not #{state}")

    next()

  @When /^I hover over (.*)$/, (namedElement, next) ->
    selector = @selectorFor(namedElement)
    element = @browser.query(selector)
    should.exist(element, "couldn't find '#{selector}'")

    @browser.fire 'mouseover', element, (error, browser, event) ->
      next()

  @When /^I hover off (.*)$/, (namedElement, next) ->
    selector = @selectorFor(namedElement)
    element = @browser.query(selector)
    should.exist(element, "couldn't find '#{selector}'")

    @browser.fire 'mouseout', element, (error, browser, event) ->
      next()

   @Then /^(.*) should (not )?be styled as (.*)$/, (namedElement, negation, cssClass, next) ->
     if negation
       stateElement = @browser.query("#{selector}.#{cssClass}")
       should.not.exist(stateElement, "Found #{selector}, but it was not supposed to exist")
     else
       selector = @selectorFor(namedElement)
       element  = @browser.query(selector)
       should.exist(element, "couldn't find '#{selector}'")

       stateElement = @browser.query("#{selector}.#{cssClass}")
       should.exist(stateElement, "Found '#{selector}' but it was not styled as #{cssClass}")

     next()

   @Then /^I select "(.*)"$/, (text, next) ->
     scope = ".modal_body.active .type-select"
     @browser.select(scope, text)

     next()

   @Then /^(.*) should be selected$/, (namedElement, next) ->
     selector = @selectorFor(namedElement)
     element  = @browser.query(selector)
     should.exist(element, "couldn't find '#{selector}'")

     stateElement = @browser.query("#{selector}:selected")
     should.exist(stateElement, "Found '#{selector}' but it was not selected")

     next()

   @Then /^there should be alert containing "([^"]*)"$/, (message, next) ->
     @browser.prompted(message).should.eql(true)
     next()

  @Then /^the application is passed the following participated demographic brand action:$/, (table, next) ->
    #this step expects a targeted poll options column
    @browser.member_filter ||= {}

    row = {}
    row.id = table.hashes()[0].id
    row.targeted_poll_options = eval(table.hashes()[0].targeted_poll_options)
    @browser.member_filter.participated_demograph_brand_actions = [row]
    next()

  @Then /^the application is passed the following participated non demographic brand action:$/, (table, next) ->
    #this step expects a targeted poll options column
    @browser.member_filter ||= {}

    row = {}
    row.id = table.hashes()[0].id
    row.targeted_poll_options = eval(table.hashes()[0].targeted_poll_options)
    @browser.member_filter.participated_non_demograph_brand_actions = [row]
    next()

  @Then /^the application is passed the following non participated brand action:$/, (table, next) ->
    @browser.member_filter ||= {}

    @browser.member_filter.non_participated_brand_actions = table.hashes()
    next()
