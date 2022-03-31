require daslib/media
require Animation
require WorldManager
require MathUtils
require Character

enum SoldierAnim
    Idle
    Walk
	Dead

enum SoldierState
	Patroling
	Wondering
	Attacking
	Victim

class Soldier : Character
	leftPos: float
	rightPos: float

	visibleByPlayer: bool
	flipped: bool
	moveLeft:bool
	wonderingTime: float = -1.0f
	aimingAngle: float = 0.0f
	shootTime: float = -1.0f
	deltaShoot: float = 0.0f

	state: SoldierState

	heartTime: float

	heartImage: ImageHandle
	torseImage: ImageHandle

	points2draw: array<float2>
	points2drawBullet: array<float2>

	sndScream : SoundHandle
	sndShoot : SoundHandle

	def override Init()

		sndScream = create_managed_sound("Assets/SFX/scream.wav")
		sndShoot = create_managed_sound("Assets/SFX/shoot.wav")

		heartImage = create_managed_image("Assets/Soldier/heart.png")
		torseImage = create_managed_image("Assets/Soldier/torse.png")

		anim = new Animator()

		var subAnim = [[Animation]]

		//Idle
		subAnim.fps = 1
		subAnim.numFrames = 1
		subAnim.looped = true
		subAnim.size = float2(58.0f, 60.0f)
		subAnim.pivot = float2(0.5f, 1.0f)
		subAnim.image = create_managed_image("Assets/Soldier/Idle.png")
		
		push(anim.anims, subAnim)

		//Walk
		subAnim.fps = 15
		subAnim.numFrames = 8
		subAnim.looped = true
		subAnim.size = float2(60.0f, 63.0f)
		subAnim.pivot = float2(0.5f, 1.0f)
		subAnim.image = create_managed_image("Assets/Soldier/Walk.png")
		
		push(anim.anims, subAnim)

		//Dead
		subAnim.fps = 10
		subAnim.numFrames = 4
		subAnim.looped = false
		subAnim.size = float2(111.0f, 71.0f)
		subAnim.pivot = float2(0.5f, 1.0f)
		subAnim.image = create_managed_image("Assets/Soldier/Death.png")
		
		push(anim.anims, subAnim)

	def override SetLimits(left: float; right: float)

		leftPos = left
		rightPos = right

	def override Reset
		pos = initPos

		var tileY : int

		if (pos.y < 0.0f)
			tileY = -int((pos.y)/ 64.0f)
		else
			tileY = -int((pos.y + 64.0f)/ 64.0f)

		pos.y = -float(tileY) * 64.0f

		SetAnim(SoldierAnim Idle);

		flipped = false;
		moveLeft = false;
		killed = false;
		wonderingTime = -1.0f;
		aimingAngle = 0.0f;

		state = SoldierState Patroling;

	def GetViewPos
		return float2(pos.x, pos.y - 64.0f)
		
	def GetDirection
		return flipped ? -1.0f : 1.0f

	def IsPlayerVisibleInSector

		return manager->IsPlayerVisibleInSector(GetViewPos(), state == SoldierState Patroling ? 750.0f : 800.0f, GetDirection() > 0.5f ? aimingAngle : 180.0f - aimingAngle, true)

	def GetAngleToPlayer

		return manager->GetAngleToPlayer(GetViewPos())

	def GetDirectionToPlayer

		return manager->GetDirectionToPlayer(GetViewPos())

	def IsVisibleByPlayer

		return manager->IsVisibleByPlayer(float2(pos.x, pos.y - 32.0f))

	def override Kill
		killed = true
		SetAnim(SoldierAnim Dead)
		sndScream |> play_sound()

	def override MakeVictim
		state = SoldierState Victim

	def SetAnim(soldierAnim: SoldierAnim)
		anim->SetAnim(int(soldierAnim))

	def override Update(dt: float)

		anim->Update(dt)

		visibleByPlayer = IsVisibleByPlayer()

		if (!killed && manager->IsPlayerHasHeartSensor())
			heartTime += dt;

			if (heartTime > 1.0f)
				heartTime -= 1.0f

		if (killed)
			return

		var moveDir: float2

		var tragetAimingAngle = aimingAngle

		if (state == SoldierState Victim)
			tragetAimingAngle = -89.0f
		elif (state == SoldierState Patroling)
			if ((moveLeft && pos.x < leftPos) || (!moveLeft && pos.x > rightPos))
				moveLeft = !moveLeft;

			tragetAimingAngle = 0.0f
			SetAnim(SoldierAnim Walk);

			moveDir.x = moveLeft ? -200.0f : 200.0f;

			if (IsPlayerVisibleInSector())
				state = SoldierState Wondering;
				wonderingTime = 1.25f

				tragetAimingAngle = GetAngleToPlayer()

			if (abs(moveDir.x) > 0.01f)
				flipped = moveDir.x < -0.01f;
		elif (state == SoldierState Wondering)
			wonderingTime -= dt;

			var playerVisibile: bool = IsPlayerVisibleInSector()

			if (playerVisibile)
				flipped = GetDirectionToPlayer() < 0.0f
				tragetAimingAngle = GetAngleToPlayer()

			if (wonderingTime < 0.0f)
				if (playerVisibile)
					state = SoldierState Attacking
					shootTime = 0.175f
					wonderingTime = 1.25f
				else
					state = SoldierState Patroling
		elif (state == SoldierState Attacking)

			if (!IsPlayerVisibleInSector())
				wonderingTime -= dt

				if (wonderingTime < 0.0f)
					wonderingTime = 1.0f
					state = SoldierState Wondering

			flipped = GetDirectionToPlayer() < 0.0f

			shootTime -= dt

			if (shootTime < 0.01f)
				shootTime = 0.175f
				deltaShoot = GetRandom()
				sndShoot |> play_sound()

				if (abs(tragetAimingAngle - aimingAngle) < 1.0f)
					manager->KillPlayer()

			tragetAimingAngle = GetAngleToPlayer()

		if (abs(aimingAngle - tragetAimingAngle) > 0.01f)
			if (tragetAimingAngle > aimingAngle)
				aimingAngle += dt * 140.0f

				if (aimingAngle > tragetAimingAngle)
					aimingAngle = tragetAimingAngle
			else
				aimingAngle -= dt * 140.0f

				if (aimingAngle < tragetAimingAngle)
					aimingAngle = tragetAimingAngle

		if (length_sq(moveDir) < 0.1f)
			SetAnim(SoldierAnim Idle)

		pos += moveDir * dt

	def DrawBullet

		if (empty(points2drawBullet))
			points2drawBullet |> resize(4)

		let angle: float = (GetDirection() > 0.5f ? aimingAngle : 180.0f - aimingAngle) + (deltaShoot - 0.5f) * 4.0f

		var side_angle : float
		var dist: float
		var pt: float2 = GetViewPos() 

		side_angle = (angle) * Radian
		dist = 40.0f
		pt = float2(cos(side_angle) * dist + pt.x, sin(side_angle) * dist + pt.y)

		side_angle = (angle + 90.0f * GetDirection()) * Radian
		dist = 7.0f
		pt = float2(cos(side_angle) * dist + pt.x, sin(side_angle) * dist + pt.y)

		side_angle = (angle - 90.0f) * Radian
		points2drawBullet[0] = float2(cos(side_angle) + pt.x, sin(side_angle) + pt.y)

		side_angle = (angle + 90.0f) * Radian
		points2drawBullet[1] = float2(cos(side_angle) + pt.x, sin(side_angle) + pt.y)

		side_angle = (angle) * Radian
		dist = manager->GetDistToPlayer(GetViewPos()) - 20.0f
		pt = float2(cos(side_angle) * dist + pt.x, sin(side_angle) * dist + pt.y)

		side_angle = (angle + 90.0f) * Radian
		points2drawBullet[2] = float2(cos(side_angle) + pt.x, sin(side_angle) + pt.y)

		side_angle = (angle - 90.0f) * Radian
		points2drawBullet[3] = float2(cos(side_angle) + pt.x, sin(side_angle) + pt.y)

		fill_convex_polygon(points2drawBullet, 0xB0FFAA00)

	def DrawViewCone

		if (empty(points2draw))
			points2draw |> resize(3)

		points2draw[0] = GetViewPos()
		
		let dist: float = state == SoldierState Patroling ? 750.0f : 800.0f
		let angle: float = (GetDirection() > 0.5f ? aimingAngle : 180.0f - aimingAngle)

		var side_angle : float = (angle - 22.5f) * Radian
		points2draw[1] = float2(cos(side_angle) * dist + points2draw[0].x, sin(side_angle) * dist + points2draw[0].y)

		side_angle = (angle + 22.5f) * Radian
		points2draw[2] = float2(cos(side_angle) * dist + points2draw[0].x, sin(side_angle) * dist + points2draw[0].y)

		fill_convex_polygon(points2draw, state == SoldierState Patroling ? 0x5000AAAA : (state == SoldierState Wondering ? 0x50AAAA00 : 0x50AA0000))


	def override Draw

		if (visibleByPlayer)
			anim->Draw(pos, 0xFFFFFFFF, flipped, false, 0.0f)

			if (!killed)
				torseImage |> draw_image_transformed(pos.x, pos.y - 64.0f, float4(0.0f, 0.0f, 65.0f, 35.0f), 0xFFFFFFFF, float2(65.0f * GetDirection(), 35.0f), aimingAngle * Radian * GetDirection(), 0.35f, 0.5f)

				DrawViewCone()

				if (state == SoldierState Attacking && shootTime < 0.075f)
					DrawBullet()

	def override DrawOverShadow

		if (!killed && manager->IsPlayerHasHeartSensor() && !visibleByPlayer)

			var alpha: float = 0.0f

			if (heartTime < 0.25f)
				alpha = heartTime * 4.0f;
			elif (heartTime < 0.5f)
				alpha = (0.5f - heartTime) * 4.0f;

			heartImage |> draw_image_transformed(pos.x, pos.y - 64.0f, float4(0.0f, 0.0f, 64.0f, 64.0f), make_color(1.0f, alpha * 0.25f), float2(alpha * 750.0f, alpha * 750.0f), 0.0f, 0.5f, 0.5f)

			let scale : float = (0.25f + alpha * 0.5) * 64.0f
			heartImage |> draw_image_transformed(pos.x, pos.y - 64.0f, float4(0.0f, 0.0f, 64.0f, 64.0f), make_color(1.0f, alpha), float2(scale, scale), 0.0f, 0.5f, 0.5f)