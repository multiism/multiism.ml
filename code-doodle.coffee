
nodes = []
connections = []
pointers = {}

canvas.setAttribute "touch-action", "none"

canvas.addEventListener "pointerdown", (e)->
	pointers[e.pointerId] = x: e.clientX, y: e.clientY
canvas.addEventListener "pointermove", (e)->
	pointer = pointers[e.pointerId]
	if pointer?
		pointer.previous_x = pointer.x
		pointer.previous_y = pointer.y
		pointer.x = e.clientX
		pointer.y = e.clientY
canvas.addEventListener "pointerup", (e)->
	delete pointers[e.pointerId]
canvas.addEventListener "pointercancel", (e)->
	delete pointers[e.pointerId]

class Node
	constructor: ->
		@x = 0
		@y = 0
		@vx = 0
		@vy = 0
		@r = 0
		@to = x: 0, y: 0, r: 20
		@level = 0
		@children = []
		@color = "hsla(#{random()*360}, 100%, #{random()*60 + 40}%, 0.6)"
		connections.push [@, @to]
		nodes.push @
	step: ->
		for pointerId, pointer of pointers
			if pointer.previous_x? and pointer.previous_y?
				pointer_movement_x = pointer.x - pointer.previous_x
				pointer_movement_y = pointer.y - pointer.previous_y
				
				dx = pointer.x - canvas.width / 2 - @x
				dy = pointer.y - canvas.height / 2 - @y
				d = sqrt(dx*dx + dy*dy)
				
				@vx += pointer_movement_x / max(10, d) * 5
				@vy += pointer_movement_y / max(10, d) * 5
			
		@x += @vx *= 0.99
		@y += @vy *= 0.99
		for [a, b] in connections when a is @
			dx = b.x - a.x
			dy = b.y - a.y
			d = sqrt(dx*dx + dy*dy)
			if b instanceof Node
				dd = (d - 10) / 400
			else
				dd = d
			a.vx += dx * dd / 55550
			a.vy += dy * dd / 55550
		unless @level > 4
			if random() < 0.01
				if @children.length < 2
					@spawn()
	draw: ->
		@r += (@to.r - @r) / 50
		ctx.globalAlpha = max(0, min(1, 100 / @r))
		ctx.fillStyle = @color
		ctx.beginPath()
		if @parent
			dx = @parent.x - @x
			dy = @parent.y - @y
			angle_to_parent = atan2(dy, dx)
			dist_to_parent = sqrt(dx*dy + dy*dy)
			dist_to_parent = 0 if isNaN dist_to_parent
			
			ctx.save()
			r = @r
			c = r * 4 * (sqrt(2)-1) / 3
			a = max(1, dist_to_parent / r)
			ctx.translate @x, @y
			ctx.rotate angle_to_parent + TAU/2
			
			ctx.moveTo +0,+r
			ctx.bezierCurveTo +c,+r,  +r,+c,  +r,+0
			ctx.bezierCurveTo +r,-c,  +c,-r,  +0,-r
			ctx.bezierCurveTo -c,-r,  -r,-c,  -r*a,+0
			ctx.bezierCurveTo -r*a,+c,  -c*a,+r,  +0,+r
			
			ctx.restore()
		else
			ctx.arc @x, @y, @r, 0, TAU
		ctx.fill()
		ctx.stroke()
	
	spawn: ->
		node = new Node
		node.level = @level + 1
		node.parent = @
		node.r *= random() * 0.8 + 0.1
		node.x = @x
		node.y = @y
		spanning_angle = (random() - 1 / 2) * TAU # "spangle"?
		node.to.x = @to.x + sin(spanning_angle) * 50
		node.to.y = @to.y - cos(spanning_angle) * 50
		connections.push [@, node]
		thing = @
		things_to_expand = []
		while thing?
			things_to_expand.push thing
			thing = thing.parent
		for thing_to_expand in things_to_expand
			thing_to_expand.to.r *= 1.1
			thing_to_expand.to.x *= 1.1
			thing_to_expand.to.y *= 1.1
		@children.push node


root = new Node
setTimeout ->
	root.spawn()
, 50

animate ->
	
	{width: w, height: h} = canvas
	
	ctx.fillStyle = "white"
	ctx.fillRect 0, 0, w, h
	
	ctx.save()
	ctx.translate(w / 2, h / 2)
	
	ctx.strokeStyle = "#222"
	ctx.lineWidth = 4
	ctx.lineCap = "round"
	
	root.x = 0
	root.y = 0
	root.vx = 0
	root.vy = 0
	node.step() for node in nodes
	node.draw() for node in nodes
	
	ctx.restore()
