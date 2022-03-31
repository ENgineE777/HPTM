
require daslib/media
require Animation
require Character

enum ChargeTankAnim
    Idle
	Dead

class ChargeTank: Character

	sndJump : SoundHandle

	def override Init

		anim = new Animator()

		var subAnim = [[Animation]]

		//Idle
		subAnim.fps = 15
		subAnim.numFrames = 4
		subAnim.looped = true
		subAnim.size = float2(64.0f, 101.0f)
		subAnim.pivot = float2(0.5f, 1.0f)
		subAnim.image = create_managed_image("Assets/Tank/Idle.png")
		
		push(anim.anims, subAnim)

		//Dead
		subAnim.fps = 1
		subAnim.numFrames = 1
		subAnim.looped = true
		subAnim.size = float2(64.0f, 101.0f)
		subAnim.pivot = float2(0.5f, 1.0f)
		subAnim.image = create_managed_image("Assets/Tank/Broken.png")

		push(anim.anims, subAnim)

		sndJump = create_managed_sound("Assets/SFX/tank_crack.wav")

	def override Kill
		sndJump |> play_sound()
		killed = true
		SetAnim(ChargeTankAnim Dead)

	def SetAnim(chargeTankAnim: ChargeTankAnim)
		anim->SetAnim(int(chargeTankAnim))

	def override Reset

		pos = initPos
		killed = false
		SetAnim(ChargeTankAnim Idle)

	def override Update(dt: float)
		anim->Update(dt)

	def override Draw
		anim->Draw(pos, 0xFFFFFFFF, false, false, 0.0f)
