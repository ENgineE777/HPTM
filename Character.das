require daslib/math
require Animation

class Character

	initPos: float2
	pos: float2
	killed: bool
	anim : Animator?

	def abstract Init() : void
	def abstract SetLimits(left: float; right: float) : void
	def abstract Reset() : void
	def abstract Kill() : void
	def abstract MakeVictim() : void
	def abstract HasHeartSensor() : bool
	def abstract Update(dt: float) : void
	def abstract Draw() : void
	def abstract DrawOverShadow() : void

