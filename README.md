# Tracker Streams

This package attempts to bake observable streams into Tracker and therefore Meteor.

If you haven't heard about observable streams, then [check out this talk](https://www.youtube.com/watch?v=XRYN2xt11Ek).

## Notes

Right now, these aren't truely observable streams because there arent any arrays. But it works right now for the click and drag example...

http://jhusain.github.io/learnrx/

<!-- Observable streams are often thought of as asynchronous arrays.
Here, they are slightly differnt because we are never accumulating
values. Basically, we just have a reactive variable in each stream
and we tie streams together with a Tracker.autorun. The crucial part
to realize here is that we keep track of all the autorun dependancies
as well so we can stop all of them when a stream has completed. -->

## To Do
- reactive arrays
- error propagation
- use [transducers](http://jlongster.com/Transducers.js--A-JavaScript-Library-for-Transformation-of-Data)



