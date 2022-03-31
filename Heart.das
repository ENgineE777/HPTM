
require daslib/media
require Character

class Heart: Character

	heartImage : ImageHandle
	timer : float = 0.0f
	sndPickup : SoundHandle

	def override Init

		heartImage = create_managed_image("Assets/Heart/heart.png")
		sndPickup = create_managed_sound("Assets/SFX/pickup.wav")

	def override Kill
		killed = true
		sndPickup |> play_sound()

	def override Reset

		pos = initPos
		killed = false

	def override Update(dt: float)
		timer += dt * 0.5f

		if (timer > 1.0f)
			timer -= 1.0f

	def override Draw
		if (!killed)
			heartImage |> draw_image(int(pos.x - 15.0f), int(pos.y - 20.0f + cos( 2.0f * PI * timer) * 5.0f - 2.5f))
