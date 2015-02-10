
Template.main.rendered = ->
  mouseDown = @eventStream("mousedown", ".draggable")
  mouseUp   = @eventStream("mouseup", ".draggable")
  self = this

  mouseDown.map (e) ->
    $elem = $(e.target)
    initPos = $elem.position()
    initOffset = {top: initPos.top - e.pageY, left:initPos.left - e.pageX}
    self.eventStream("mousemove", "*")
      .takeUntil(mouseUp)
      .forEach (e) ->
        pos = {top: e.pageY, left: e.pageX}
        $elem.css({top: pos.top + initOffset.top, left: pos.left + initOffset.left})
