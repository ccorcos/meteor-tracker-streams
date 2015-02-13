navHeight = 50
menuWidth = 200
css('*:not(input):not(textarea)').userSelect('none').boxSizing('border-box')
css('.menu').transform("translateX(-#{menuWidth}px)")
css('html body .page').fp().margin(0)

css
  '.menu':
    zIndex: 1
    position: 'absolute'
    top: 0
    bottom: 0
    rightpc: 100
    widthpx: menuWidth
    left: 0
    color: 'white'
    backgroundColor: 'blue'
    '.handle':
      position: 'absolute'
      top: 0
      leftpc: 100
      heightpx: navHeight
      widthpx: navHeight
      lineHeightpx: navHeight
      textAlign: 'center'
      backgroundColor: 'red'
    '.item':
      widthpc: 100
      textAlign: 'center'
      heightpx: navHeight
      borderBottom: '1px solid white'
      lineHeightpx: navHeight
  '.content':
    paddingpx: 10
    position: 'absolute'
    toppx: navHeight 
    bottom: 0
    left: 0
    right: 0
  '.nav':
    position: 'absolute'
    top: 0
    left: 0
    right: 0
    heightpx: navHeight
    color: 'white'
    backgroundColor: 'blue'

strangle = (x, maxMin) ->
  x = Math.max(x, maxMin[0])
  x = Math.min(x , maxMin[1])
  return x

Template.menu.rendered = ->
  self = this

  # start stream of x position values
  toushStart = @eventStream("touchstart", ".handle")
    .map (e) -> e.originalEvent.touches[0].pageX
  mouseDown = @eventStream("mousedown", ".handle")
    .map (e) -> e.pageX
  startStream = Tracker.mergeStreams(toushStart, mouseDown)

  # cancel on a variety of annoying events
  touchEnd = self.eventStream("touchend", ".page", true)
  touchCancel = self.eventStream("touchcancel", ".page", true)
  touchLeave = self.eventStream("touchleave", ".page", true)
  mouseUp   = self.eventStream("mouseup", ".page", true)
  mouseOut  = self.eventStream("mouseout", ".page", true)
  mouseOffPage = mouseOut
    .filter (e) -> (e.relatedTarget or e.toElement) is undefined
  endStream = Tracker.mergeStreams(mouseUp, mouseOffPage, touchEnd, touchCancel, touchLeave)

  # create a move stream on demand returning the x position values
  MoveStream = ->
    mouseMove = self.eventStream("mousemove", ".page", true)
      .map (e) -> e.pageX
    touchMove = self.eventStream("touchmove", ".page", true)
      .map (e) -> e.originalEvent.touches[0].pageX
    return Tracker.mergeStreams(mouseMove, touchMove)

  # create an animation stream to block the start stream from interrupting an animation
  animatingStream = @stream(false)

  # get the jquery object we're going to drag
  $menu = $(@find('.menu'))

  startStream
    .unless(animatingStream)
    .map (x) ->
      moveStream = MoveStream()

      initLeft = $menu.position().left
      offset = initLeft - x
      lastLeft = initLeft
      velocity = 0

      # toggle menu position
      toggle = ->
        if lastLeft > -menuWidth/2
          # close it
          $menu.velocity({translateX: [-menuWidth, 0], translateZ: [0, 0]}, {duration: 400, easing: 'ease-in-out', complete: -> animatingStream.set(false)})
        else
          # open it
          $menu.velocity({translateX: [0, -menuWidth], translateZ: [0, 0]}, {duration: 400, easing: 'ease-in-out', complete: -> animatingStream.set(false)})

      # resolve menu position
      resolve = ->
        animatingStream.set(true)
        # wait for animation to finish
        if initLeft is lastLeft and velocity is 0
          toggle()
          return

        momentum = velocity*3
        if lastLeft + momentum > -menuWidth/2
          momentum = Math.abs(momentum)
          duration = Math.min(-lastLeft/momentum*100, 400)
          $menu.velocity({translateX: 0, translateZ: 0}, {duration: duration, easing: 'ease-out', complete: -> animatingStream.set(false)})
        else
          momentum = Math.abs(momentum)
          duration = Math.min((200-lastLeft)/momentum*100, 400)
          $menu.velocity({translateX: -menuWidth, translateZ: 0}, {duration: duration, easing: 'ease-out', complete: -> animatingStream.set(false)})
      
      moveStream
        .stopWhen(endStream, resolve)
        .forEach (x) ->
          # wait for animation to finish
          left = strangle(x + offset, [-menuWidth, 0])
          velocity = left - lastLeft
          lastLeft = left
          $menu.velocity({translateX: left, translateZ: 0}, {duration: 0})


