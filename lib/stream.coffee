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

# A curried function for merging streams into one
Tracker.mergeStreams = (streams...) ->
  mergedStream = new Tracker.stream()

  subs = []
  for stream in streams
    do (stream) ->
      stream.subscribers.push(mergedStream)
      sub = Tracker.autorun ->
        value = stream.value.get()
        if value isnt undefined
          mergedStream.set(value)
      subs.push(sub)

  s = stop: ->
    for sub in subs
      sub.stop()

  mergedStream.subscription = s
  return mergedStream

# Add a value to a stream
Tracker.stream::set = (x) ->
  @value.set(x)

# Get a value from a stream
Tracker.stream::get = () ->
  @value.get()

# Stop a stream, i.e. its subscription, and its subscribers.
Tracker.stream::stop = () ->
  # stop this stream.
  @subscription?.stop()
  # stop the subscribers
  for subscriber in @subscribers
    subscriber.stop()

# Create a stream from an event on an element
Tracker.eventStream = (eventName, element) ->
  if not (this instanceof Tracker.eventStream) then return new Tracker.eventStream(eventName, element)
  stream = new Tracker.stream()
  debug "New event stream #{eventName} #{element}"
  # create stream from an event using jquery
  element.bind eventName, (e) ->
    debug "event:", eventName
    stream.set(e)

  # set the subscription to unbind the event on stop
  stream.subscription = 
    stop: ->
      debug "Stop event stream #{eventName} #{element}"
      element.unbind(eventName)

  return stream

# Map the stream across a function
Tracker.stream::map = (func) ->
  self = this
  nextStream = new Tracker.stream()
  @subscribers.push(nextStream)
  nextStream.subscription = Tracker.autorun -> 
    value = self.get()
    if value isnt undefined
      nextStream.set(func(value))
  return nextStream

# Create a dupelicate stream
Tracker.stream::copy = () ->
  @map((x)-> x)

# Filter the stream based on a function
Tracker.stream::filter = (func) ->
  self = this
  nextStream = new Tracker.stream()
  @subscribers.push(nextStream)
  nextStream.subscription = Tracker.autorun -> 
    value = self.get()
    if value isnt undefined and func(value)
      nextStream.set(value)
  return nextStream

# Reduce a stream
Tracker.stream::reduce = (initialValue, func) ->
  self = this
  nextStream = new Tracker.stream(initialValue)
  @subscribers.push(nextStream)
  lastValue = initialValue
  nextStream.subscription = Tracker.autorun -> 
    value = self.get()
    if value isnt undefined
      nextStream.set(func(value, lastValue))
      lastValue = value
  return nextStream

# Filter consecutive duplicate values
Tracker.stream::dedupe = (func) ->
  lastValue = undefined
  @filter (value) ->
    notDupe = (lastValue isnt value)
    lastValue = value
    return notDupe

# The most recent value of a stream with a minimum amount of 
# time since the last value
Tracker.stream::debounce = (ms) ->
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
        nextStream.set(waitingValue)
        debug "wait again"
        wait()
      else
        waiting = false
        debug "done waiting"

  nextStream.subscription = Tracker.autorun -> 
    value = self.get()
    if value isnt undefined
      if waiting
        debug "queue value"
        waitingValue = value
      else
        waitingValue = undefined
        debug "set value"
        nextStream.set(value)
        wait()

  return nextStream

# Merge with another stream into a new stream
Tracker.stream::merge = (anotherStream) ->
  self = this
  nextStream = new Tracker.stream()

  @subscribers.push(nextStream)
  sub1 = Tracker.autorun -> 
    value = self.get()
    if value isnt undefined
      nextStream.set(value)

  anotherStream.subscribers.push(nextStream)
  sub2 = Tracker.autorun -> 
    value = anotherStream.value.get()
    if value isnt undefined
      nextStream.set(value)

  sub = stop: ->
    sub1.stop()
    sub2.stop()

  nextStream.subscription = sub
  return nextStream

# Stop on the next event from anotherStream.
Tracker.stream::stopWhen = (anotherStream, func) ->
  self = this
  first = true
  Tracker.autorun (c) ->
    value = anotherStream.value.get()
    if value isnt undefined
      # there may already be a value in another stream, so make sure
      # not to immediately stop the stream.
      unless first
        self.stop()
        c.stop()
        val = self.get()
        if func then func(val)
    first = false
  return this

# Stop stream after some time
Tracker.stream::stopAfterMs = (ms, func) ->
  self = this
  delay ms, ->
    self.stop()
    value = self.get()
    if func then func(value)
  return this

# Stop stream after N values
Tracker.stream::stopAfterN = (number, func) ->
  self = this
  count = 0
  Tracker.autorun (c) ->
    value = self.get()
    if value isnt undefined
      count++
      if count >= number
        self.stop()
        c.stop()
        if func then func(value)
  return this

# Alias for stream.copy().stopWhen
Tracker.stream::takeUntil = (anotherStream, func) ->
  @copy().stopWhen(anotherStream, func)

# Alias for stream.copy().stopAfterMs
Tracker.stream::takeForMs = (ms, func) ->
  @copy().stopAfterMs(ms, func)

# Alias for stream.copy().stopAfterN
Tracker.stream::takeN = (number, func) ->
  @copy().stopAfterN(number, func)

# Aliases
Tracker.stream::push = Tracker.stream::set
Tracker.stream::read = Tracker.stream::get
Tracker.stream::completed = Tracker.stream::stop

Tracker.stream::forEach = Tracker.stream::map
Tracker.stream::throttle = Tracker.stream::debounce

# Create a Blaze prototype for creating event streams that automatically stop onDestroyed
Blaze.TemplateInstance.prototype.eventStream = (eventName, elementSelector, global=false) ->
  unless @eventStreams isnt undefined
    @eventStreams = []

  # if you set global, the event stream still closes onDestroyed
  # but this way you can do things lik `this.eventStream("mousemove", "*")`
  # and it selectes everything.
  if global
    element = $(elementSelector)
    stream = Tracker.eventStream(eventName, element)
    @eventStreams.push(stream)
    return stream

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
      stream.set(e)
    @view.template.events(evtMap)
    @eventStreams.push(stream)
    return stream

# Clean up all the streams when the Template dies thanks to 
# the template-extentions package
Template.onDestroyed ->
  _.map(@eventStreams, (stream) -> stream.stop())