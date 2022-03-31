
require daslib/media
require Animation
require WorldManager
require MathUtils
require Character

enum TurretState
	Watching
	Rotating
	Wondering
	Attacking

class Turret : Character
	leftAngle: float
	rightAngle: float

	aimingAngle: float
	rotateLeft: bool

	visibleByPlayer: bool
	waitTime: float = -1.0f
	shootTime: float = -1.0f
	deltaShoot: float = 0.0f

	state: TurretState

	heartTime: float

	gunImage: ImageHandle
	baseImage: ImageHandle

	points2draw: array<float2>
	points2drawBullet: array<float2>

	sndShoot : SoundHandle
	sndElectroHit :SoundHandle

	def override Init()

		gunImage = create_managed_image("Assets/Turret/gun.png")
		baseImage = create_managed_image("Assets/Turret/base.png")
		sndShoot = create_managed_sound("Assets/SFX/shoot.wav")
		sndElectroHit = create_managed_sound("Assets/SFX/electro_hit.wav")

	def override SetLimits(left: float; right: float)

		leftAngle = left
		rightAngle = right

	def override Reset
		pos = initPos
		killed = false;

		aimingAngle = leftAngle
		rotateLeft = false
		state = TurretState Rotating

	def GetViewDist
		return (state == TurretState Watching || state == TurretState Rotating) ? 750.0f : 800.0f

	def GetViewPos
		return float2(pos.x, pos.y + 32.0f)

	def IsPlayerVisibleInSector

		return manager->IsPlayerVisibleInSector(GetViewPos(), GetViewDist(), aimingAngle, true)

	def GetAngleToPlayer

		var res : float = manager->GetAngleToPlayer(GetViewPos())

		if (manager->GetDirectionToPlayer(pos) < 0.0f)
			res = -res + 180.0f

		return res

	def GetDirectionToPlayer

		return manager->GetDirectionToPlayer(GetViewPos())

	def IsVisibleByPlayer

		return manager->IsVisibleByPlayer(GetViewPos())


	def override Kill
		killed = true

	def override Update(dt: float)

		visibleByPlayer = IsVisibleByPlayer()

		if (killed)
			return

		var tragetAimingAngle = aimingAngle

		if (state == TurretState Rotating)

			if (rotateLeft)
				aimingAngle += dt * 35.0f

				if (aimingAngle > leftAngle)
					aimingAngle = leftAngle
					rotateLeft = false
					waitTime = 4.0f
					state = TurretState Watching
			else
				aimingAngle -= dt * 35.0f
				
				if (aimingAngle < rightAngle)
					aimingAngle = rightAngle
					rotateLeft = true
					waitTime = 4.0f
					state = TurretState Watching

			if (IsPlayerVisibleInSector())
				waitTime = 1.0f
				state = TurretState Wondering

		elif (state == TurretState Watching)
			waitTime -= dt

			if (waitTime < 0.0f)
				state = TurretState Rotating

			if (IsPlayerVisibleInSector())
				waitTime = 1.0f
				state = TurretState Wondering
		elif (state == TurretState Wondering)

			waitTime -= dt;

			var playerVisibile: bool = IsPlayerVisibleInSector()

			if (playerVisibile)
				tragetAimingAngle = GetAngleToPlayer()

			if (waitTime < 0.0f)
				if (playerVisibile)
					state = TurretState Attacking
					shootTime = 0.175f
					waitTime = 1.0f
				else
					state = TurretState Rotating
		elif (state == TurretState Attacking)

			if (!IsPlayerVisibleInSector())
				waitTime -= dt

				if (waitTime < 0.0f)
					waitTime = 1.0f
					state = TurretState Wondering

			tragetAimingAngle = GetAngleToPlayer()

			shootTime -= dt

			if (shootTime < 0.01f)
				shootTime = 0.175f
				deltaShoot = GetRandom()
				sndShoot |> play_sound()

				if (abs(tragetAimingAngle - aimingAngle) < 1.0f)
					manager->KillPlayer()
				
		if ((state == TurretState Attacking || state == TurretState Wondering) && abs(aimingAngle - tragetAimingAngle) > 0.01f)
			if (tragetAimingAngle > aimingAngle)
				aimingAngle += dt * 140.0f

				if (aimingAngle > tragetAimingAngle)
					aimingAngle = tragetAimingAngle

				if (aimingAngle > leftAngle)
					aimingAngle = leftAngle
			else
				aimingAngle -= dt * 140.0f

				if (aimingAngle < tragetAimingAngle)
					aimingAngle = tragetAimingAngle

				if (aimingAngle < rightAngle)
					aimingAngle = rightAngle

		if (manager->GetDistToPlayer(pos) < 32.0f)
			sndElectroHit |> play_sound()
			manager->KillPlayer()

	def DrawBullet

		if (empty(points2drawBullet))
			points2drawBullet |> resize(4)

		let angle: float = aimingAngle + (deltaShoot - 0.5f) * 4.0f

		var side_angle : float
		var dist: float
		var pt: float2 = GetViewPos() 

		side_angle = (angle) * Radian
		dist = 40.0f
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
		
		let dist: float = (state == TurretState Watching || state == TurretState Rotating) ? 750.0f : 800.0f
		let angle: float = aimingAngle

		var side_angle : float = (angle - 22.5f) * Radian
		points2draw[1] = float2(cos(side_angle) * dist + points2draw[0].x, sin(side_angle) * dist + points2draw[0].y)

		side_angle = (angle + 22.5f) * Radian
		points2draw[2] = float2(cos(side_angle) * dist + points2draw[0].x, sin(side_angle) * dist + points2draw[0].y)

		fill_convex_polygon(points2draw, state == TurretState Attacking ? 0x50AA0000 : (state == TurretState Wondering ? 0x50AAAA00 : 0x5000AAAA))

	def override Draw

		if (visibleByPlayer)
			DrawViewCone()

		baseImage |> draw_image(int(pos.x) - 7, int(pos.y))
		gunImage |> draw_image_transformed(pos.x, pos.y + 32.0f, float4(0.0f, 0.0f, 73.0f, 33.0f), 0xFFFFFFFF, float2(73.0f, 33.0f), aimingAngle * Radian, 0.35f, 0.5f)

		if (state == TurretState Attacking && shootTime < 0.075f)
			DrawBullet()
