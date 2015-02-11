# Some helper functions
debug = (args...) -> return #console.log.apply(console, args)
delay = (ms, func) -> Meteor.setTimeout(func, ms)

Tracker.stream = (initialValue=undefined) ->
  if not (this instanceof Tracker.stream) then return new Tracker.stream(initialValue)
  # Keep track of any autorun "subscribers" so we can stop them when complete
  @subscribers = []
  # keep track of the autorun this stream subscribes to so we can stop it as well
  @subscription = undefined
  # second arguement is an equals function. we want repeat values.
  @value = new ReactiveVar(initialValue, -> false)
  @error = new ReactiveVar(undefined, -> false)
  return this

Tracker.stream::completed = () ->
  # stop this stream.
  @subscription?.stop()
  # stop the subscribers
  for subscriber in @subscribers
    subscriber.completed()

Tracker.eventStream = (eventName, element) ->
  if not (this instanceof Tracker.eventStream) then return new Tracker.eventStream(eventName, element)
  stream = new Tracker.stream()
  debug "New event stream #{eventName} #{element}"
  # create stream from an event using jquery
  element.bind eventName, (e) ->
    debug "event:", eventName
    stream.value.set(e)

  # set the subscription to unbind the event on stop
  stream.subscription = 
    stop: ->
      debug "Stop event stream #{eventName} #{element}"
      element.unbind(eventName)

  return stream

Blaze.TemplateInstance.prototype.eventStream = (eventName, elementSelector) ->
  unless @eventStreams isnt undefined
    @eventStreams = []

  if @view.isRendered
    # if the view is already rendered, we can use TemplateInstance.$ to 
    # find all elements within the template and create an event stream
    element = @$(elementSelector)
    stream = Tracker.eventStream(eventName, element)
    @eventStreams.push(stream)
    return stream
  else
    # if the view hasnt been rendered yet (e.g. Template.created)
    # we can register events with Template.events. We don't have
    # to worry about unsubscribing -- Meteor does that :)
    stream = new Tracker.stream()
    evtMap = {}
    evtMap["#{eventName} #{elementSelector}"] = (e,t) ->
      stream.value.set(e)
    @view.template.events(evtMap)
    @eventStreams.push(stream)
    return stream

# Clean up all the streams when the Template dies thanks to 
# the template-extentions package
Template.onDestroyed ->
  _.map(@eventStreams, (stream) -> stream.completed())

# It would be great to use transducers for all these high-order functions
Tracker.stream::map = (func) ->
  self = this
  nextStream = new Tracker.stream()
  @subscribers.push(nextStream)
  nextStream.subscription = Tracker.autorun -> 
    value = self.value.get()
    if value isnt undefined
      nextStream.value.set(func(value))
  return nextStream

Tracker.stream::throttle = (ms) ->
  self = this
  nextStream = new Tracker.stream()
  @subscribers.push(nextStream)

  waiting = false
  waitingValue = undefined
  wait = ->
    waiting = true
    waitingValue = undefined
    debug "start waiting"
    delay ms, ->
      if waitingValue isnt undefined
        nextStream.value.set(waitingValue)
        debug "wait again"
        wait()
      else
        waiting = false
        debug "done waiting"

  nextStream.subscription = Tracker.autorun -> 
    value = self.value.get()
    if value isnt undefined
      if waiting
        debug "queue value"
        waitingValue = value
      else
        waitingValue = undefined
        debug "set value"
        nextStream.value.set(value)
        wait()

  return nextStream

Tracker.stream::filter = (func) ->
  self = this
  nextStream = new Tracker.stream()
  @subscribers.push(nextStream)
  nextStream.subscription = Tracker.autorun -> 
    value = self.value.get()
    if value isnt undefined and func(value)
      nextStream.value.set(value)
  return nextStream

Tracker.stream::forEach = (func) ->
  self = this
  # Sort of a phony stream. But it is definitely a subscriber
  nextStream = new Tracker.stream()
  @subscribers.push(nextStream)
  nextStream.subscription = Tracker.autorun -> 
    value = self.value.get()
    if value isnt undefined
      func(value)
  return

Tracker.stream::takeUntil = (anotherStream) ->
  self = this
  first = true
  Tracker.autorun (c) ->
    if anotherStream.value.get() isnt undefined
      unless first
        self.completed()
        c.stop()
    first = false
  return this

# Tracker.stream::take = (number) ->
#   self = this
#   count = 0
#   Tracker.autorun (c) ->
#     if @stream.value.get() isnt undefined
#       count++
#       if count >= number
#         self.completed()
#         c.stop()
#   return this
