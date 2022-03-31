require daslib/media

struct Animation
	image: ImageHandle
	fps: int
	numFrames: int
	looped: bool
	size: float2
	pivot: float2

class Animator
	anims: array<Animation>
	curAnim: int
	curFrame: int
	curTime: float

	def SetAnim(anim: int)
		if anim != curAnim
			curAnim = anim
			curFrame = 0
			curTime = 0.0f

	def Update(dt: float)

		var anim: Animation = anims[curAnim]

		if (anim.numFrames == 1)
			return

		curTime += dt
		let frameTime = 1.0f / float(anim.fps)

		while(curTime > frameTime)

			curTime -= frameTime
			curFrame++

			if (curFrame == anim.numFrames)
				curFrame = anim.looped ? 0 : curFrame - 1

	def Draw(pos: float2; color: uint; flippedH: bool; flippedV: bool; angle: float)

		var anim = anims[curAnim]

		var rect : float4

		rect.x = anim.size.x * float(curFrame)
		rect.y = 0.0f
		rect.z = anim.size.x
		rect.w = anim.size.y

		var size = anim.size
		size.x *= flippedH ? -1.0f : 1.0f
		size.y *= flippedV ? -1.0f : 1.0f

		anim.image |> draw_image_transformed(pos.x, pos.y, rect, color, size, angle, anim.pivot.x, anim.pivot.y)