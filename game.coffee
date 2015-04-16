class Habitat
  constructor: (@game, attrs = {}) ->
    @[k] = v for k, v of attrs

class Blip
  constructor: (@game, @attrs = {}) ->
    @[k] = v for k, v of @attrs

  live: ->
    destination = null
    destDistance = 1/0
    for h in @game.habitats
      d = @circle.touchDistance(h.circle)
      if d < destDistance
        destination = h
        destDistance = d
    if destination?
      goTowards = destination.circle.center
      goVector = goTowards.minus(@circle.center)
      vector = V2Polar(Math.min(@speed, goVector.magnitude()), goVector.angle())
      @circle.center = @circle.center.plus vector
    @age++
    @age < @expire

  inHabitat: ->
    for h in @game.habitats
      return true if @circle.inside(h.circle)
    false

class Circle
  constructor: (attrs = {}) ->
    @[k] = v for k, v of attrs

  # Returns the shortest distance between the two circles, or 0 if they are touching.
  touchDistance: (other) ->
    Math.min(0, @center.distance(other.center) - @radius - other.radius)

  centerDistance: (other) ->
    @center.distance(other.center)

  inside: (other) ->
    @radius < other.radius and @centerDistance(other) < other.radius - @radius

class V2
  constructor: (@x, @y) ->

  plus: ({x, y}) ->
    new V2(@x + x, @y + y)

  minus: ({x, y}) ->
    new V2(@x - x, @y - y)

  times: ({x, y}) ->
    new V2(@x * x, @y * y)

  distance: ({x, y}) ->
    Math.sqrt((@x - x) ** 2 + (@y - y) ** 2)

  magnitude: ->
    @distance new V2(0, 0)

  angle: ->
    Math.atan2 @y, @x

V2Polar = (r, theta) ->
  new V2(r * Math.cos(theta), r * Math.sin(theta))

class Game
  constructor: (@canvas) ->
    @ctx = canvas.getContext '2d'
    @habitats =
      [ new Habitat @,
        circle: new Circle
          center: new V2(35, 35)
          radius: 30
      ]
    @blips =
      [ new Blip @,
        circle: new Circle
          center: new V2(0, 0)
          radius: 5
        speed: 1
        age: 0
        breed: [300, 400, 500, 600, 700]
        expire: 1000
        health: 50
      ]
    @center = new V2 0, 0
    @zoom = 3

  drawCircle: (x, y, r, fill) ->
    @ctx.beginPath()
    @ctx.arc x, y, r, 0, 2 * Math.PI, false
    @ctx.fillStyle = fill
    @ctx.fill()

  draw: ->
    @ctx.fillStyle = '#888'
    @ctx.fillRect 0, 0, @canvas.width, @canvas.height
    canvasCenter = new V2(@canvas.width * 0.5, @canvas.height * 0.5)
    for h in @habitats
      {x, y} = h.circle.center.minus(@center).times(new V2 @zoom, @zoom).plus(canvasCenter)
      r = h.circle.radius * @zoom
      @drawCircle x, y, r, '#33a'
    for b in @blips
      {x, y} = b.circle.center.minus(@center).times(new V2 @zoom, @zoom).plus(canvasCenter)
      r = b.circle.radius * @zoom
      @ctx.globalAlpha = 1 - b.age / b.expire
      @drawCircle x, y, r, if b.inHabitat() then '#3a3' else '#a33'
      @ctx.globalAlpha = 1
    @ctx.fillStyle = 'black'
    @ctx.font = '20px monospace'
    @ctx.fillText "(#{@center.x.toFixed(3)}, #{@center.y.toFixed(3)})", 10, 25

  mousedown: (@clickPosn) ->
    @clickCenter = @center

  mousemove: (posn) ->
    if @clickPosn?
      offset = posn.minus(@clickPosn).times(new V2(1 / @zoom, 1 / @zoom))
      @center = @clickCenter.minus(offset)
      @draw()

  mouseup: (posn) ->
    @mousemove posn
    delete @clickPosn

  tick: ->
    @blips =
      b for b in @blips when b.live()

$(document).ready ->
  canvas = $('#the-canvas')[0]
  window.game = new Game canvas
  handle = (mouseEvent) -> (e) ->
    {left, top} = $('#the-canvas').offset()
    window.game[mouseEvent] new V2(e.pageX - left, e.pageY - top)
  $('#the-canvas').mousedown handle('mousedown')
  $(document).mousemove handle('mousemove')
  $(document).mouseup handle('mouseup')
  resize = ->
    canvas.width = $(window).width()
    canvas.height = $(window).height()
  resize()
  $(window).resize -> resize()
  (gameLoop = ->
    window.game.tick()
    window.game.draw()
    requestAnimationFrame gameLoop
  )()
