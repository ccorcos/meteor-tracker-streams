# Session.setDefault('example', 'drag')
Session.setDefault('example', 'typeahead')

Template.registerHelper 'sessionVarEq', (string, value) -> Session.equals(string, value)

Template.main.events
  'click .switch': (e,t) ->
    state = Session.get('example')
    if state is 'drag'
      Session.set('example', 'typeahead')
    else
      Session.set('example', 'drag')


Template.drag.rendered = ->
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

People = new Mongo.Collection(null)

for i in [0...1000]
  People.insert({name: Fake.word()})


Template.typeahead.created =  ->
  @keyUp = @eventStream("keyup", ".typeahead")

Template.typeahead.helpers
  matches: () ->
    t = Template.instance()
    
    searchStream = t.keyUp
      .map (e) -> e.key
      # non alphanumeric keys are things like "Backspace", etc.
      .filter (key) -> key?.length is 1 or key is "Backspace"
      .throttle(1500)
      .map (key) ->
        text = t.find('.typeahead').value
        if text.length > 0
          return People.find({name:{$regex: ".*#{text}.*"}})
        else 
          return []
    
    searchStream.value.get()
