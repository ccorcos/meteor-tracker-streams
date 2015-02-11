# Tracker Streams

This package uses Tracker to build "observable streams" for Meteor. [Check out the live demo](http://tracker-streams.meteor.com).

If you haven't heard about observable streams, then [check out this talk](https://www.youtube.com/watch?v=XRYN2xt11Ek).
For a more hands-on introduction, check out [this interactive tutorial](http://jhusain.github.io/learnrx/).

## Getting Started

    meteor add ccorcos:tracker-streams

You can create you're own stream using

    numbers = Tracker.stream()

You can create new streams using `map`, `forEach`, `filter`, etc.

    times10 = myStream.map (x) -> x*10
    times10.forEach (x) -> console.log x

Now you push to the stream by setting the stream's reactive variable.

    numbers.value.set(10)
    # log: 100
    numbers.value.set(2)
    # log: 20

Tracker is pretty amazing and you could say that this isn't that useful.
But what about when we create streams from events?

Suppose we want to make an element draggable. We can do this by creating
an event stream for mousedown and mouseup events. Then after mousedown, 
we can create a mousemove stream which completes on the next mouseup event
using `.takeUntil`. Check it out:

    Template.drag.rendered = ->
      # create the mouseDown and mouseUp streams that will 
      # be automatically completed on Template.destroyed.
      mouseDown = @eventStream("mousedown", ".draggable")
      mouseUp   = @eventStream("mouseup", ".draggable")
      
      self = this
      mouseDown.map (e) ->
        # on each mousedown, get the initial position and the offset of the click
        $elem = $(e.target)
        initPos = $elem.position()
        initOffset = {top: initPos.top - e.pageY, left:initPos.left - e.pageX}
        # create a new event stream to listen to mousemove until mouseUp
        self.eventStream("mousemove", "*")
          .takeUntil(mouseUp)
          .forEach (e) ->
            # update the position of the element
            pos = {top: e.pageY, left: e.pageX}
            $elem.css({top: pos.top + initOffset.top, left: pos.left + initOffset.left})

Pretty cool right? Imagine of all the state you could have to manage if you
used events as opposed to streams. To help with your imagination, [here's some
code I'm not terribly proud of](https://github.com/ccorcos/meteor-swipe/blob/3f1efdff1f1e1280d46f2715496df0f21a353cb8/swipe/swipe.coffee#L332).

So what else can you so with `Tracker.eventStreams`? As you can see, it helps 
eliminate state from your templates...

Check out the following example of typeahead suggestions. After creating 
an eventStream listening to keyup on the input, we implement everything 
else right in the template helper! Because we're using Tracker, the 
helper reactively updates just as you'd expect.

Now for the sake of the demo, we also throttle the the input. This would
be very useful if you need to subscribe for results before displaying
them. This way, you aren't blasting your server on every keyup.

We also do something pretty unconventional with observable streams -- we
return the value of the searchStream to the helper. However unconventional,
it works like a charm!

    Template.typeahead.created =  ->
      @keyUp = @eventStream("keyup", ".typeahead")

    Template.typeahead.helpers
      matches: () ->
        t = Template.instance()
        
        searchStream = t.keyUp
          # map to the key name
          .map (e) -> e.key
          # non alphanumeric keys are things like "Meta". But
          # we want to update on "Backspace" still.
          .filter (key) -> key?.length is 1 or key is "Backspace"
          # throttle the stream to every 1.5 seconds
          .throttle(1500)
          .map (key) ->
            text = t.find('.typeahead').value
            # Meteor.subscribe("typeahead", text)
            if text.length > 0
              return People.find({name:{$regex: ".*#{text}.*"}})
            else 
              return []
        
        # return the latest value in the searchStream
        searchStream.value.get()
      
As you can see, we once again eliminated a lot of state from out template.
We didn't have to keep track of the search text in a reactive variable, and
we didn't have to throttle the results in the template logic. In a large template
it could become a hassle to trace how the internal state changes with respect
to events ([again, some code I'm not very proud of](https://github.com/ccorcos/meteor-swipe/blob/3f1efdff1f1e1280d46f2715496df0f21a353cb8/swipe/swipe.coffee#L325)). 
With observable streams, we can eliminate state with more declarative asynchronous
code. [Check out these examples in action](http://tracker-streams.meteor.com).

## Implementation Details

Observable streams are often thought of as asynchronous arrays.
But in the end, we never deal with arrays, just one element at a time.
`Tracker.stream` accomplished all of this with a reactive variable and 
subscriptions are created with `Tracker.autorun`. 
The "completion" of a stream results in stopping the `Tracker.autorun` 
computation for a stream's subscription and all of its subscribers.

## To Do
- error propagation

    I haven't come up with a good example to use this yet, but when I do
    I will implement them.

- use [transducers](http://jlongster.com/Transducers.js--A-JavaScript-Library-for-Transformation-of-Data) to create more high order functions.

    It would be sweet to recreate underscore or lodash at the same time ;)



