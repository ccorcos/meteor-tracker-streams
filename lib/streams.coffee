
debug = (args...) -> return #console.log.apply(console, args)

# for arrays, stream needs .next(value) and .error(value)
# subscribers thus need an "onError" optional callback as well as the onNext

Tracker.stream = (initialValue=undefined) ->
  if not (this instanceof Tracker.stream) then return new Tracker.stream(initialValue)
  @subscribers = []
  @subscription = undefined
  @value = new ReactiveVar(initialValue)
  @error = new ReactiveVar(undefined)
  return this

Tracker.stream::completed = () ->
  @subscription?.stop()
  for subscriber in @subscribers
    subscriber.completed()

Tracker.stream::map = (func) ->
  self = this
  nextStream = new Tracker.stream()
  @subscribers.push(nextStream)
  nextStream.subscription = Tracker.autorun -> 
    value = self.value.get()
    if value isnt undefined
      nextStream.value.set(func(value))
  return nextStream

Tracker.stream::filter = (func) ->
  self = this
  nextStream = new Tracker.stream()
  @subscribers.push(nextStream)
  nextStream.subscription = Tracker.autorun -> 
    value = self.value.get()
    if func(value)
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


Tracker.eventStream = (eventName, element) ->
  if not (this instanceof Tracker.eventStream) then return new Tracker.eventStream(eventName, element)
  stream = new Tracker.stream()

  debug "New event stream #{eventName} #{element}"

  element.bind eventName, (e) ->
    debug "event:", eventName
    stream.value.set(e)

  subscription = 
    stop: ->
      debug "Stop event stream #{eventName} #{element}"
      element.unbind(eventName)

  stream.subscription = subscription

  return stream


Blaze.TemplateInstance.prototype.eventStream = (eventName, elementSelector) ->
  unless @eventStreams isnt undefined
    @eventStreams = []
  element = @$(elementSelector)
  stream = Tracker.eventStream(eventName, element)
  @eventStreams.push(stream)
  return stream

Template.onDestroyed ->
  _.map(@eventStreams, (stream) -> stream.completed())
