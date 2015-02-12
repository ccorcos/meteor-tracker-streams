navHeight = 50
menuWidth = 200
css('*:not(input):not(textarea)').userSelect('none').boxSizing('border-box')


css
  'html body .page':
    margin: 0
    position: 'absolute'
    top: 0
    bottom: 0
    left: 0
    right: 0
  '.menu':
    zIndex: 1
    position: 'absolute'
    top: 0
    bottom: 0
    rightpc: 100
    widthpx: menuWidth
    left: 0
    transform: "translateX(-#{menuWidth}px)"
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

Template.main.rendered = ->
  mouseDown = @eventStream("mousedown", ".handle")
  mouseUp   = @eventStream("mouseup", "*")
  # touchDown = @eventStream("touchstart", ".draggable")
  # touchUp   = @eventStream("touchend", ".draggable")
  self = this

  $menu = $(@find('.menu'))

  mouseDown.map (e) ->
    initPos = $menu.position()
    offset = initPos.left - e.pageX
    lastLeft = initPos.left
    velocity = 0
    self.eventStream("mousemove", "*")
      .takeUntil mouseUp, (e) ->
        momentum = velocity*1
        if lastLeft + momentum > -menuWidth/2
          easing = 'ease-in-out'
          console.log momentum
          if momentum > menuWidth/20
            easing = 'ease-out'
          $menu.velocity({translateX: 0, translateZ: 0}, {duration: 400, easing: easing})
        else
          easing = 'ease-in-out'
          if momentum < -menuWidth/20
            easing = 'ease-out'
          $menu.velocity({translateX: -menuWidth, translateZ: 0}, {duration: 400, easing: easing})
      .forEach (e) ->
        left = strangle(e.pageX + offset, [-menuWidth, 0])
        velocity = left - lastLeft
        lastLeft = left
        $menu.velocity({translateX: left, translateZ: 0}, {duration: 0})


