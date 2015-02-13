# Tracker.stream API

Create a stream with an optional

```coffee
Tracker.stream = (initialValue=undefined) ->
```

A curried function for merging streams into one

```coffee
Tracker.mergeStreams = (streams...) ->
```

Create a stream from an event on an element

```coffee
Tracker.eventStream = (eventName, element) ->
```

A Blaze prototype function for creating event streams that automatically stop onDestroyed

```coffee
Blaze.TemplateInstance.prototype.eventStream = (eventName, elementSelector, global=false) ->
```

Add a value to a stream

```coffee
Tracker.stream::set = (x) ->
```

Get a value from a stream

```coffee
Tracker.stream::get = () ->
```

Stop a stream, i.e. its subscription, and its subscribers.

```coffee
Tracker.stream::stop = () ->
```

Map the stream across a function

```coffee
Tracker.stream::map = (func) ->
```

Create a dupelicate stream

```coffee
Tracker.stream::copy = () ->
```

Filter the stream based on a function

```coffee
Tracker.stream::filter = (func) ->
```

Reduce a stream

```coffee
Tracker.stream::reduce = (initialValue, func) ->
```

Filter consecutive duplicate values

```coffee
Tracker.stream::dedupe = (func) ->
```

The most recent value of a stream with a minimum amount of 
time since the last value

```coffee
Tracker.stream::debounce = (ms) ->
```

Merge with another stream into a new stream

```coffee
Tracker.stream::merge = (anotherStream) ->
```

Stop on the next event from anotherStream.

```coffee
Tracker.stream::stopWhen = (anotherStream, func) ->
```

Stop stream after some time

```coffee
Tracker.stream::stopAfterMs = (ms, func) ->
```

Stop stream after N values

```coffee
Tracker.stream::stopAfterN = (number, func) ->
```

Alias for stream.copy().stopWhen

```coffee
Tracker.stream::takeUntil = (anotherStream, func) ->
```

Alias for stream.copy().stopAfterMs

```coffee
Tracker.stream::takeForMs = (ms, func) ->
```

Alias for stream.copy().stopAfterN

```coffee
Tracker.stream::takeN = (number, func) ->
```

Some other aliases
```coffee
Tracker.stream::push = Tracker.stream::set
Tracker.stream::read = Tracker.stream::get
Tracker.stream::completed = Tracker.stream::stop
Tracker.stream::forEach = Tracker.stream::map
Tracker.stream::throttle = Tracker.stream::debounce
```

