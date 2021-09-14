/*=======*\
| ENEMIES |
\*=======*/

::Enemy <- class extends PhysAct {
	health = 1
	hspeed = 0.0
	vspeed = 0.0
	active = false
	frozen = 0
	icebox = -1

	function run() {
		//Collision with player
		if(active) {
			if(gvPlayer != 0) {
				if(hitTest(shape, gvPlayer.shape) && !frozen) { //8 for player radius
					if(gvPlayer.invincible > 0) hurtinvinc()
					else if(y > gvPlayer.y && vspeed < gvPlayer.vspeed && gvPlayer.canstomp) gethurt()
					else if(gvPlayer.rawin("anSlide")) {
						if(gvPlayer.anim == gvPlayer.anSlide) gethurt()
						else hurtplayer()
					}
					else hurtplayer()
				}
			}

			//Collision with fireball
			if(actor.rawin("Fireball")) foreach(i in actor["Fireball"]) {
				if(hitTest(shape, i.shape)) {
					hurtfire()
					deleteActor(i.id)
				}
			}
			if(actor.rawin("FlameBreath")) foreach(i in actor["FlameBreath"]) {
				if(hitTest(shape, i.shape)) {
					hurtfire()
					deleteActor(i.id)
				}
			}
			if(actor.rawin("Iceball")) foreach(i in actor["Iceball"]) {
				if(hitTest(shape, i.shape)) {
					hurtice()
					deleteActor(i.id)
				}
			}
		}
		else {
			if(distance2(x, y, camx + (screenW() / 2), camy + (screenH() / 2)) <= 180) active = true
		}

		if(active && frozen > 0) {
			frozen--
			if(getFrames() % 15 == 0) {
				newActor(Glimmer, shape.x - (shape.w + 4) + randInt((shape.w * 2) + 8), shape.y - (shape.h + 4) + randInt((shape.h * 2) + 8))
				if(randInt(50) % 2 == 0) newActor(Glimmer, shape.x - (shape.w + 4) + randInt((shape.w * 2) + 8), shape.y - (shape.h + 4) + randInt((shape.h * 2) + 8))
			}
		}
	}

	function gethurt() {} //Spiked enemies can just call hurtplayer() here

	function hurtplayer() { //Default player damage
		if(gvPlayer.blinking > 0) return
		if(gvPlayer.x < x) gvPlayer.hspeed = -1.0
		else gvPlayer.hspeed = 1.0
		gvPlayer.hurt = true
	}

	function hurtfire() {} //If the object is hit by a fireball
	function hurtice() { frozen = 600 }

	function hurtinvinc() {
		newActor(Poof, x, y)
		deleteActor(id)
		playSound(sndFlame, 0)
	}

	function _typeof() { return "Enemy" }
}

::Deathcap <- class extends Enemy {
	frame = 0.0
	flip = false
	squish = false
	squishTime = 0.0
	smart = false

	constructor(_x, _y) {
		base.constructor(_x.tofloat(), _y.tofloat())
		shape = Rec(x, y, 4, 6, 0)
		if(gvPlayer != 0) if(x > gvPlayer.x) flip = true
	}

	function run() {
		base.run()

		if(active) {
			if(!squish) {
				if(placeFree(x, y + 1)) vspeed += 0.1
				if(placeFree(x, y + vspeed)) y += vspeed
				else vspeed /= 2

				if(y > gvMap.h + 8) deleteActor(id)

				if(!frozen) {
					if(flip) {
						if(placeFree(x - 0.5, y)) x -= 0.5
						else if(placeFree(x - 1.1, y - 0.5)) {
							x -= 0.5
							y -= 0.25
						} else if(placeFree(x - 1.1, y - 1.0)) {
							x -= 0.5
							y -= 0.5
						} else flip = false
						/*
						There's a simpler way to do this in theory,
						but it doesn't work in practice.
						It should be this:

						else if(placeFree(x - 1.0, y - 1.0)) {
							x -= 1.0
							y -= 1.0
						}

						But for whatever reason, this prevents any
						movement over a slope that looks like \_.
						Instead, they just turn around when they reach
						the bottom of a slope facing right.

						This weird trick of checking twice ahead works,
						though. Credit to Admiral Spraker for giving me
						the idea. Another fine example of (/d/d/d).
						*/

						if(smart) if(placeFree(x - 8, y + 16)) flip = false

						if(x <= 0) flip = false
					}
					else {
						if(placeFree(x + 1, y)) x += 0.5
						else if(placeFree(x + 1.1, y - 0.5)) {
							x += 0.5
							y -= 0.25
						} else if(placeFree(x + 1.1, y - 1.0)) {
							x += 0.5
							y -= 0.5
						} else flip = true

						if(smart) if(placeFree(x + 8, y + 16)) flip = true

						if(x >= gvMap.w) flip = true
					}
				}

				if(frozen) {
					//Create ice block
					if(gvPlayer != 0) if(icebox == -1 && !hitTest(shape, gvPlayer.shape)) {
						icebox = mapNewSolid(shape)
					}

					//Draw
					if(smart) drawSpriteEx(sprGradcap, 0, floor(x - camx), floor(y - camy), 0, flip.tointeger(), 1, 1, 1)
					else drawSpriteEx(sprDeathcap, 0, floor(x - camx), floor(y - camy), 0, flip.tointeger(), 1, 1, 1)

					if(frozen <= 120) {
					if(floor(frozen / 4) % 2 == 0) drawSprite(sprIceTrapSmall, 0, x - camx - 1 + ((floor(frozen / 4) % 4 == 0).tointeger() * 2), y - camy - 1)
						else drawSprite(sprIceTrapSmall, 0, x - camx, y - camy - 1)
					}
					else drawSprite(sprIceTrapSmall, 0, x - camx, y - camy - 1)
				}
				else {
					//Delete ice block
					if(icebox != -1) {
						mapDeleteSolid(icebox)
						newActor(IceChunks, x, y)
						icebox = -1
						if(gvPlayer != 0) if(x > gvPlayer.x) flip = true
						else flip = false
					}

					//Draw
					if(smart) drawSpriteEx(sprGradcap, wrap(getFrames() / 12, 0, 3), floor(x - camx), floor(y - camy), 0, flip.tointeger(), 1, 1, 1)
					else drawSpriteEx(sprDeathcap, wrap(getFrames() / 12, 0, 3), floor(x - camx), floor(y - camy), 0, flip.tointeger(), 1, 1, 1)
				}
			}
			else {
				squishTime += 0.025
				if(squishTime >= 1) deleteActor(id)
				if(smart) drawSpriteEx(sprDeathcap, floor(4.8 + squishTime), floor(x - camx), floor(y - camy), 0, flip.tointeger(), 1, 1, 1)
				else drawSpriteEx(sprDeathcap, floor(4.8 + squishTime), floor(x - camx), floor(y - camy), 0, flip.tointeger(), 1, 1, 1)
			}

			shape.setPos(x, y)
			setDrawColor(0xff0000ff)
			if(debug) shape.draw()
		}
	}

	function hurtplayer() {
		if(squish) return
		base.hurtplayer()
	}

	function gethurt() {
		if(squish) return

		if(gvPlayer.rawin("anSlide")) {
			if(gvPlayer.anim == gvPlayer.anSlide) {
				local c = newActor(DeadNME, x, y)
				actor[c].sprite = sprDeathcap
				actor[c].vspeed = -abs(gvPlayer.hspeed * 1.05)
				actor[c].hspeed = (gvPlayer.hspeed / 16)
				actor[c].spin = (gvPlayer.hspeed * 6)
				actor[c].angle = 180
				deleteActor(id)
				playSound(sndKick, 0)
			}
			else if(keyDown(config.key.jump)) gvPlayer.vspeed = -5
			else {
				gvPlayer.vspeed = -2
				playSound(sndSquish, 0)
			}
			if(gvPlayer.anim == gvPlayer.anJumpT || gvPlayer.anim == gvPlayer.anFall) {
				gvPlayer.anim = gvPlayer.anJumpU
				gvPlayer.frame = gvPlayer.anJumpU[0]
			}
		}
		else if(keyDown(config.key.jump)) gvPlayer.vspeed = -5
		else gvPlayer.vspeed = -2
		if(gvPlayer.anim == gvPlayer.anJumpT || gvPlayer.anim == gvPlayer.anFall) {
			gvPlayer.anim = gvPlayer.anJumpU
			gvPlayer.frame = gvPlayer.anJumpU[0]
		}

		squish = true
	}

	function hurtfire() {
		newActor(Flame, x, y - 1)
		deleteActor(id)
		playSound(sndFlame, 0)
	}

	function _typeof() { return "Deathcap" }
}

::PipeSnake <- class extends Enemy {
	ystart = 0
	timer = 60
	up = false
	flip = 1

	constructor(_x, _y) {
		base.constructor(_x, _y)
		ystart = y
		shape = Rec(x, y, 8, 12, 0)
		timer = (x * y) % 60
	}

	function run() {
		base.run()

		if(up && y > ystart - 24 && !frozen) y--
		if(!up && y < ystart && !frozen) y++

		timer--
		if(timer <= 0) {
			up = !up
			timer = 120
		}

		shape.setPos(x, y + 16)
		if(frozen) {
			//Create ice block
			if(gvPlayer != 0) if(icebox == -1 && !hitTest(shape, gvPlayer.shape)) {
				icebox = mapNewSolid(shape)
			}

			if(flip == 1) drawSpriteEx(sprSnake, 1, floor(x - camx), floor(y - camy), 0, 0, 1, 1, 1)
			if(flip == -1) drawSpriteEx(sprSnake, 1, floor(x - camx), floor(y - camy) - 8, 0, 2, 1, 1, 1)
			if(frozen <= 120) {
				if(floor(frozen / 4) % 2 == 0) drawSprite(sprIceTrapTall, 0, x - camx - 1 + ((floor(frozen / 4) % 4 == 0).tointeger() * 2), y - camy + 16)
				else drawSprite(sprIceTrapTall, 0, x - camx, y - camy + 16)
			}
			else drawSprite(sprIceTrapTall, 0, x - camx, y - camy + 16)
		}
		else {
			//Delete ice block
			if(icebox != -1) {
				mapDeleteSolid(icebox)
				newActor(IceChunks, x, ystart - 6)
				icebox = -1
			}

			if(flip == 1) drawSpriteEx(sprSnake, getFrames() / 20, floor(x - camx), floor(y - camy), 0, 0, 1, 1, 1)
			if(flip == -1) drawSpriteEx(sprSnake, getFrames() / 20, floor(x - camx), floor(y - camy) - 8, 0, 2, 1, 1, 1)
		}
	}

	function gethurt() {
		if(gvPlayer.anim != gvPlayer.anSlide) hurtplayer()
		else hurtfire()
	}

	function hurtfire() {
		newActor(Flame, x, ystart - 6)
		deleteActor(id)
		playSound(sndFlame, 0)
	}

	function _typeof() { return "Snake" }
}

::Ouchin <- class extends Enemy {
	sf = 0.0

	constructor(_x, _y) {
		base.constructor(_x, _y)
		shape = Rec(x, y, 8, 8, 0)
		sf = randInt(8)
	}

	function run() {
		base.run()

		drawSprite(sprOuchin, sf + (getFrames() / 16), x - camx, y - camy)

		if(gvPlayer != 0) if(hitTest(shape, gvPlayer.shape)) {
			if(x > gvPlayer.x) {
				gvPlayer.x--
				gvPlayer.hspeed -= 0.1
			}

			if(x < gvPlayer.x) {
				gvPlayer.x++
				gvPlayer.hspeed += 0.1
			}

			if(y > gvPlayer.y) {
				gvPlayer.y--
				gvPlayer.vspeed -= 0.1
			}

			if(y < gvPlayer.y) {
				gvPlayer.y++
				gvPlayer.vspeed += 0.1
			}
		}
	}

	function gethurt() { hurtplayer() }

	function hurtfire() {
		newActor(Poof, x, y)
		deleteActor(id)
		playSound(sndFlame, 0)
	}
}

//Dead enemy effect for enemies that get sent flying,
//like when hit with a melee attack
::DeadNME <- class extends Actor {
	sprite = 0
	frame = 0
	hspeed = 0.0
	vspeed = 0.0
	angle = 0.0
	spin = 0

	constructor(_x, _y) {
		base.constructor(_x, _y)
		vspeed = -3.0
	}

	function run() {
		vspeed += 0.1
		x += hspeed
		y += vspeed
		angle += spin
		if(y > gvMap.h + 32) deleteActor(id)
		drawSpriteEx(sprite, frame, floor(x - camx), floor(y - camy), angle, 0, 1, 1, 1)
	}
}