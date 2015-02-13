Session.setDefault('a', 0)
Session.setDefault('b', 1)
Session.setDefault('c', false)

c1 = Tracker.autorun ->
  console.log "c1"
  Session.set('b', Session.get('a'))

Tracker.autorun (c2) ->
  console.log "c2"
  if Session.get('c')
    console.log "stop"
    Session.set('a', 2)
    Meteor.defer ->
      c1.stop()
      c2.stop()

console.log Session.get('a'), Session.get('b'), Session.get('c')
Session.set('c', true)
console.log Session.get('a'), Session.get('b'), Session.get('c')