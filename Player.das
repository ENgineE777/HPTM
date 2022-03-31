require daslib/media
require TileMap
require Animation
require WorldManager
require Character
require MathUtils

enum TunnelTransitionType
    NotAvailable
    LeftRight
    Down
    Up

enum PlayerAnim
    Idle
    Run
    Fall
    Jump
	Dead

enum PlayerAbility
	Speed
	HeartSensor
	DeathFromAbove
	AcidShot
	StoneSkin
	ChargeFromTanks
	TwoSlots

struct Ability
	opened: bool
	name : string

class Player : Character

	tileIndex: int = -1
	
 	inJumpAttack: float = -1.0f
	inAcidShoot: float = -1.0f
	onWall: bool = false
	onCelling: bool = false
	flipped: bool = false
	flippedV: bool = false
	inTunnelTransition: bool = false
	tunnelTransitionPos: float = -1.0f
	cameraPos: float2
	cameraZoom: float = 1.0f

	abilities : array<Ability>

	selectAbility: bool = true
	abilitiesToSelect: array<int>

	inKillFromAbove: bool = false

	stoneSkill: float = -1.0f

	charges: int = 1

	acidInUse: bool = false
	acidPos: float2
	acidDir: float
	acidBorder: float
	acidImage: ImageHandle

	tunnelTransitionType : TunnelTransitionType = TunnelTransitionType NotAvailable

	pray : Character?
	chargeTank : Character?

	uiFLeft : ImageHandle
	uiFRight: ImageHandle
	uiFUp : ImageHandle
	uiFDown : ImageHandle
	uiRDown : ImageHandle
	uiRPlus : ImageHandle
	ui1 : ImageHandle
	ui2 : ImageHandle
	ui3 : ImageHandle
	uiLeftClosed : ImageHandle
	uiLeftOpened : ImageHandle
	uiRightClosed : ImageHandle
	uiRightOpened : ImageHandle
	uiSlotCharged : ImageHandle
	uiSlotEmpty : ImageHandle
	uiGameOver : ImageHandle
	uiOutro : ImageHandle

	introShadow : ImageHandle
	introShadowWithP : ImageHandle
	inIntroScene: bool = false
	introStage: int = 0
	introTimer: float = 0.0f
	animEgg : Animator?
	animHeart : Animator?

	escaped : bool = false
	deadAlpha : float = 0.0f

	sndJump : SoundHandle
	sndEggCrack : SoundHandle
	sndHeartBeat : SoundHandle
	sndHeartBeatInPlay : PlayingSoundHandle
	sndRun : SoundHandle
	sndRunInPlay : PlayingSoundHandle


	def override Init()

		var subAnim = [[Animation]]

		animHeart = new Animator()

		//Idle
		subAnim.fps = 15
		subAnim.numFrames = 13
		subAnim.looped = true
		subAnim.size = float2(40.0f, 30.0f)
		subAnim.pivot = float2(0.5f, 0.0f)
		subAnim.image = create_managed_image("Assets/Egg/heart.png")
		
		push(animHeart.anims, subAnim)

		animEgg = new Animator()

		//Idle
		subAnim.fps = 1
		subAnim.numFrames = 1
		subAnim.looped = true
		subAnim.size = float2(47.0f, 47.0f)
		subAnim.pivot = float2(0.5f, 0.0f)
		subAnim.image = create_managed_image("Assets/Egg/Idle.png")
		
		push(animEgg.anims, subAnim)

		//Idle
		subAnim.fps = 12
		subAnim.numFrames = 5
		subAnim.looped = false
		subAnim.size = float2(93.0f, 83.0f)
		subAnim.pivot = float2(0.5f, 0.0f)
		subAnim.image = create_managed_image("Assets/Egg/Crush.png")
		
		push(animEgg.anims, subAnim)

		anim = new Animator()

		//Idle
		subAnim.fps = 1
		subAnim.numFrames = 1
		subAnim.looped = true
		subAnim.size = float2(71.0f, 18.0f)
		subAnim.pivot = float2(0.75f, 0.25f)
		subAnim.image = create_managed_image("Assets/FaceHugger/Idle.png")
		
		push(anim.anims, subAnim)

		//Run
		subAnim.fps = 15
		subAnim.numFrames = 8
		subAnim.looped = true
		subAnim.size = float2(84.0f, 20.0f)
		subAnim.pivot = float2(0.75f, 0.25f)
		subAnim.image = create_managed_image("Assets/FaceHugger/Run.png")

		push(anim.anims, subAnim)
		
		//Fall
		subAnim.fps = 1
		subAnim.numFrames = 1
		subAnim.looped = true
		subAnim.size = float2(48.0f, 32.0f)
		subAnim.pivot = float2(0.75f, 0.75f)
		subAnim.image = create_managed_image("Assets/FaceHugger/Fall.png")
		
		push(anim.anims, subAnim)

		//Jump
		subAnim.fps = 15
		subAnim.numFrames = 4
		subAnim.looped = true
		subAnim.size = float2(47.0f, 52.0f)
		subAnim.pivot = float2(0.65f, 0.5f)
		subAnim.image = create_managed_image("Assets/FaceHugger/Jump.png")
		
		push(anim.anims, subAnim)

		//Dead
		subAnim.fps = 1
		subAnim.numFrames = 1
		subAnim.looped = true
		subAnim.size = float2(46.0f, 32.0f)
		subAnim.pivot = float2(0.75f, 0.5f)
		subAnim.image = create_managed_image("Assets/FaceHugger/Dead.png")
		
		push(anim.anims, subAnim)

		acidImage = create_managed_image("Assets/FaceHugger/acid.png")
		
		uiFLeft = create_managed_image("Assets/GUI/F_left.png")
		uiFRight = create_managed_image("Assets/GUI/F_right.png")
		uiFUp = create_managed_image("Assets/GUI/F_up.png")
		uiFDown = create_managed_image("Assets/GUI/F_down.png")

		ui1 = create_managed_image("Assets/GUI/1.png")
		ui2 = create_managed_image("Assets/GUI/2.png")
		ui3 = create_managed_image("Assets/GUI/3.png")

		uiRDown = create_managed_image("Assets/GUI/R_down.png")
		uiRPlus = create_managed_image("Assets/GUI/R_plus.png")

		uiLeftClosed = create_managed_image("Assets/GUI/Left_closed.png")
		uiLeftOpened = create_managed_image("Assets/GUI/Left_opened.png")

		uiRightClosed = create_managed_image("Assets/GUI/Right_closed.png")
		uiRightOpened = create_managed_image("Assets/GUI/Right_opened.png")

		uiSlotCharged = create_managed_image("Assets/GUI/SlotChraged.png")
		uiSlotEmpty = create_managed_image("Assets/GUI/SlotEmpty.png")

		introShadow = create_managed_image("Assets/GUI/IntroShadow.png")
		introShadowWithP = create_managed_image("Assets/GUI/IntroShadowWithP.png")

		uiGameOver = create_managed_image("Assets/GUI/Gameover.png")

		uiOutro = create_managed_image("Assets/GUI/OutroShadow.png")

		abilities |> resize(7)

		for ability in abilities
			ability = [[Ability]]

		abilities[0].name = "Speed"
		abilities[1].name = "Heart sensor"
		abilities[2].name = "Death from above"
		abilities[3].name = "Acid shot"
		abilities[4].name = "Stone skin"
		abilities[5].name = "Charge from tanks"
		abilities[6].name = "Two slots"

		sndJump = create_managed_sound("Assets/SFX/jump.wav")
		sndEggCrack = create_managed_sound("Assets/SFX/egg_crack.wav")
		sndHeartBeat = create_managed_sound("Assets/SFX/heart-beat.wav")
		sndRun = create_managed_sound("Assets/SFX/run.mp3")

	def IsAbilityOpened(ability: PlayerAbility)
		return abilities[int(ability)].opened

	def easeOutQuad(x: float)
		return 1.0f - (1.0f - x) * (1.0f - x);

	def GetDirection
		return flipped ? -1.0f : 1.0f;

	def SetAnim(playerAnim: PlayerAnim)
		anim->SetAnim(int(playerAnim))

	def override HasHeartSensor
		return IsAbilityOpened(PlayerAbility HeartSensor)
		
	def override Reset
		pos = initPos
		cameraPos = initPos

		inJumpAttack = -1.0f
		onWall = false
		onCelling = false
		flipped = false
		flippedV = false
		inTunnelTransition = false
		charges = 1
		killed = false
		inKillFromAbove = false

		deadAlpha = 0.0f
		sndHeartBeatInPlay = sndHeartBeat |> play_sound_loop(1.0f)

		selectAbility = false

		SetAnim(PlayerAnim Idle)

		stop_sound(sndRunInPlay)

		for ability in abilities
			ability.opened = false

		inIntroScene = true
		introStage = 0
		introTimer = 0.0f
		cameraZoom = 8.0f

		animEgg->SetAnim(0)

		setup_2d_camera(pos)

	def NumChargeSlots
		return IsAbilityOpened(PlayerAbility TwoSlots) ? 2 : 1

	def override Kill
		if (stoneSkill > 0.0f)
			return

		killed = true
		SetAnim(PlayerAnim Dead)
		stop_sound(sndRunInPlay)

	def UpdateCamera
		let horz: float = 150.0f
		let vert: float = 50.0f

		if (cameraPos.x < pos.x - horz)
			cameraPos.x = pos.x - horz

		if (cameraPos.x > pos.x + horz)
			cameraPos.x = pos.x + horz

		if (cameraPos.y > pos.y + vert)
			cameraPos.y = pos.y + vert

		if (cameraPos.y < pos.y - vert)
			cameraPos.y = pos.y - vert

		cameraPos.x = floor(cameraPos.x)
		cameraPos.y = floor(cameraPos.y)

		setup_2d_camera(cameraPos, cameraZoom)

	def UpdateIntroScene(dt:float)

		if (introStage == 0)

			if get_key_down(VK_P)
				introStage++
				introTimer = 0.0f

		elif (introStage == 1)
			introTimer += dt * 0.33f

			sndHeartBeatInPlay |> set_sound_volume(1.0f - introTimer) 

			if (introTimer > 1.0f)
				cameraZoom = 1.0f
				introStage++
				animEgg->SetAnim(1)
				sndEggCrack |> play_sound()
				stop_sound(sndHeartBeatInPlay)
				introTimer = 0.0f
			else
				cameraZoom = 8.0f - introTimer * 7.0f
		elif (introStage == 2)

			introTimer += dt

			if (introTimer > 0.45f)
				introStage++
				introTimer = 0.0f
			else
				pos.y += 250.0f * dt
		elif (introStage == 3)

			introTimer += dt

			if (introTimer > 2.25f)
				inIntroScene = false

		animEgg->Update(dt)
		animHeart->Update(dt)

	def UpdateSelectAbility()

		var index : int = -1
		if get_key_down(VK_1)
			index = 0

		if get_key_down(VK_2) && length(abilitiesToSelect) > 1
			index = 1

		if get_key_down(VK_3) && length(abilitiesToSelect) > 2
			index = 2

		if (index != -1)
		
			sndJump |> play_sound()
			abilities[abilitiesToSelect[index]].opened = true
			selectAbility = false

	def override Update(dt:float)

		UpdateCamera()

		if (inIntroScene)
			UpdateIntroScene(dt)
			return

		if (escaped)
			deadAlpha += dt
			if (deadAlpha > 1.0f)
				deadAlpha = 1.0f

			if get_key_down(VK_P)
				manager->Reset()
			return
		else
			stop_sound(sndRunInPlay)
			escaped = manager->PlayerHaveReachedEscape()

		var tileMap: TileMap? = manager.tileMap

		if (acidInUse)
			acidPos.x += dt * 600.0f * acidDir

			if ((acidDir > 0.0f && acidPos.x + 16.0f > acidBorder) || (acidDir < 0.0f && acidPos.x - 16.0f < acidBorder))
				acidInUse = false
			else
				var victim : Character? = manager->FindAttackVictim(acidPos)

				if (victim != null)
					victim->Kill()
					acidInUse = false

		if (killed)

			deadAlpha += dt

			if (deadAlpha > 1.0f)
				deadAlpha = 1.0f

			var dir: float2 = pos - cameraPos

			if (length(dir) > 0.01f)
				let len: float = length(dir)

				if (len < dt * 200.0f)
					cameraPos = pos
				else
					dir = normalize(dir)
					cameraPos += dir * dt * 200.0f

			if get_key_down(VK_P)
				manager->Reset()
				return

		if get_key_down(VK_O)
			manager->Reset()
			return	

		if (manager->TryGrabHeart())

			selectAbility = true
			stop_sound(sndRunInPlay)

			clear(abilitiesToSelect)

			for i in range(0, length(abilities))
				if (!abilities[i].opened)
					push(abilitiesToSelect, i)

			let count = length(abilitiesToSelect)

			for i in range(0, 15)
				let from : int = int(float(count) * 0.99f * GetRandom())
				let to : int = int(float(count) * 0.99f * GetRandom())
				let tmp: int = abilitiesToSelect[from]
				abilitiesToSelect[from] = abilitiesToSelect[to]
				abilitiesToSelect[to] = tmp

			if (length(abilitiesToSelect) > 3)
				abilitiesToSelect |> resize(3)

			if (length(abilitiesToSelect) == 0)
				selectAbility = false


		if (selectAbility)

			UpdateSelectAbility()

			return

		var moveDir: float2

		var moveSpeed: float = 350.0f;
		var wallMoveSpeed: float = 250.0f;
		let attackMoveSpeed: float = 450.0f;
		let gravitySpeed: float = 300.0f;
		let attackJumpTime: float = 0.35f;
		let intoTunnelSpeed: float = 250.0f;

		if (IsAbilityOpened(PlayerAbility Speed))
			moveSpeed *= 1.25f;
			wallMoveSpeed *= 1.25f;

		tileIndex = tileMap->FindTileIndex(pos)
		
		if (tileIndex == -1)
			return
		
		let tile = tileMap.tiles[tileIndex]

		if (killed)
			moveDir.y = gravitySpeed
		elif (inKillFromAbove)
			moveDir.y = gravitySpeed;

			if (pray.pos.y - 96.0f < pos.y)
				pray->Kill()
				pray = null

				if (charges < NumChargeSlots() && stoneSkill < -0.5f)
					charges++

				inKillFromAbove = false;

				SetAnim(PlayerAnim Idle)

		elif (inTunnelTransition)

			SetAnim(PlayerAnim Jump)

			if (tunnelTransitionType == TunnelTransitionType LeftRight)
				if (flipped)
					if (pos.x - intoTunnelSpeed * dt < tunnelTransitionPos)
						pos.x = tunnelTransitionPos
						tunnelTransitionType = TunnelTransitionType NotAvailable
						inTunnelTransition = false
						flipped = !flipped
					else
						moveDir.x = -intoTunnelSpeed
				else
					if (pos.x + intoTunnelSpeed * dt > tunnelTransitionPos)
						pos.x = tunnelTransitionPos
						tunnelTransitionType = TunnelTransitionType NotAvailable
						inTunnelTransition = false
						flipped = !flipped
					else
						moveDir.x = intoTunnelSpeed

			elif (tunnelTransitionType == TunnelTransitionType Down)
				if (pos.y + intoTunnelSpeed * dt > tunnelTransitionPos)
					pos.y = tunnelTransitionPos
					tunnelTransitionType = TunnelTransitionType NotAvailable
					inTunnelTransition = false
				else
					moveDir.y = intoTunnelSpeed

			elif (tunnelTransitionType == TunnelTransitionType Up)
				if (pos.y - intoTunnelSpeed * dt < tunnelTransitionPos)
					pos.y = tunnelTransitionPos
					tunnelTransitionType = TunnelTransitionType NotAvailable
					inTunnelTransition = false
				else
					moveDir.y = -intoTunnelSpeed

		elif (inAcidShoot > -0.01f)
			inAcidShoot -= dt;

			if (inAcidShoot < 0.0f)
				inAcidShoot = -1.0f
				acidInUse = true
				acidPos = pos
				acidDir = GetDirection()

				var acidTile : Tile = tile

				if (acidDir > 0.0f)
					while (acidTile.right != -1 && tileSet[tileMap.tiles[acidTile.right].tileIndex].kind == 0)
						acidTile = tileMap.tiles[acidTile.right]
					
					acidBorder = float(acidTile.x + 1) * 64.0f
				else
					while (acidTile.left != -1 && tileSet[tileMap.tiles[acidTile.left].tileIndex].kind == 0)
						acidTile = tileMap.tiles[acidTile.left]
					
					acidBorder = float(acidTile.x) * 64.0f
				
			else
				moveDir.y = -easeOutQuad(1.0f - inAcidShoot / attackJumpTime) * 250.0f
				moveDir.x = GetDirection() * attackMoveSpeed * 0.5f

		elif (inJumpAttack > -0.01f)
			inJumpAttack -= dt

			if (inJumpAttack < 0.0f)
				inJumpAttack = -1.0f
			else
				moveDir.y = -easeOutQuad(1.0f - inJumpAttack / attackJumpTime) * 250.0f
				moveDir.x = GetDirection() * attackMoveSpeed

				var victim: Character? = manager->FindPlayerAttackVictim()

				if (victim != null)
					victim->Kill()

					if (charges < NumChargeSlots() && stoneSkill < -0.5f)
						charges++
		else
			var canJump = false

			if (tile.down != -1 && tileSet[tileMap.tiles[tile.down].tileIndex].kind != 0)
				if (pos.y + 18.0f == -float((tile.y - 1) * tileHeight))
					canJump = true

			if ((onWall || onCelling) && get_key(VK_W))
				SetAnim(PlayerAnim Run)
				moveDir.x = GetDirection() * moveSpeed
				moveDir.y = -wallMoveSpeed

				if (onWall)
					flippedV = false;

			if ((onWall || canJump || onCelling) && get_key(VK_S))
				SetAnim(PlayerAnim Run)
				moveDir.y = wallMoveSpeed;

				if (onWall)
					flippedV = true;

			if (get_key(VK_A))
				SetAnim(PlayerAnim Run)
				moveDir.x = -moveSpeed;

			if (get_key(VK_D))
				SetAnim(PlayerAnim Run)
				moveDir.x = moveSpeed;

			if (flipped && tile.left != -1 && tileSet[tileMap.tiles[tile.left].tileIndex].kind != 0 &&
				pos.x < float(tile.x * tileWidth) + 22.0f)
				onWall = true
			elif (!flipped && tile.right != -1 && tileSet[tileMap.tiles[tile.right].tileIndex].kind != 0 &&
				pos.x > float((tile.x + 1) * tileWidth) - 22.0f)
				onWall = true
			else
				onWall = false

			if (tile.up != -1 && tileSet[tileMap.tiles[tile.up].tileIndex].kind != 0 &&
				pos.y < -float(tile.y * tileHeight) + 22.0f)
				onCelling = true
			else
				onCelling = false

			if (!onWall)
				flippedV = onCelling;

			if (onCelling && IsAbilityOpened(PlayerAbility DeathFromAbove))
				pray = manager->FindDeadFromAboveVictim()

				if (pray != null && get_key_down(VK_R))
					pray->MakeVictim()
					inKillFromAbove = true
					SetAnim(PlayerAnim Jump)

			if (canJump && IsAbilityOpened(PlayerAbility ChargeFromTanks))
				chargeTank = manager->FindChargeTank()

				if (chargeTank != null && charges < NumChargeSlots() && get_key_down(VK_R))
					chargeTank->Kill()
					chargeTank = null
					charges++

			if (stoneSkill < -0.5f)
				if (charges > 0 && IsAbilityOpened(PlayerAbility StoneSkin) && get_key_down(VK_Q))
					stoneSkill = 3.0f
					charges--
			else
				stoneSkill -= dt;

				if (stoneSkill < 0.01f)
					stoneSkill = -1.0f;

			if (length_sq(moveDir) < 0.1f)
				SetAnim(PlayerAnim Idle)

			if (!onWall && canJump && IsAbilityOpened(PlayerAbility AcidShot) && get_key_down(VK_E) && !acidInUse && charges > 0)
				inAcidShoot = attackJumpTime * 0.5f
				charges--
				SetAnim(PlayerAnim Jump)
				sndJump |> play_sound()

			if (!onWall && canJump && get_key_down(VK_SPACE))
				inJumpAttack = attackJumpTime;
				sndJump |> play_sound()
				SetAnim(PlayerAnim Jump)

			if (!canJump && !onWall && !onCelling)
				SetAnim(PlayerAnim Fall)

			if (inJumpAttack < -0.5f && inAcidShoot < -0.5f && !onWall && !onCelling)
				moveDir.y = gravitySpeed;

			tunnelTransitionType = TunnelTransitionType NotAvailable

			if (canJump || onWall)
				if ((flipped && tile.left != -1 && tileSet[tileMap.tiles[tile.left].tileIndex].kind == 3) ||
					(!flipped && tile.right != -1 && tileSet[tileMap.tiles[tile.right].tileIndex].kind == 3))
					let y : float = -float(tile.y) * 64.0f

					if (y + 8.0f < pos.y && pos.y < y + 56.0f)
						tunnelTransitionType = TunnelTransitionType LeftRight
						tunnelTransitionPos = flipped ? float(tile.x - 1) * 64.0f - 18.0f : float(tile.x + 2) * 64.0f + 18.0f

			if (canJump)
				if (tile.down != -1 && tileSet[tileMap.tiles[tile.down].tileIndex].kind == 2)
					let x : float = float(tile.x) * 64.0f

					if (x + 8.0f < pos.x && pos.x < x + 56.0f)
						tunnelTransitionType = TunnelTransitionType Down
						tunnelTransitionPos = -float(tile.y - 1) * 64.0f + 64.0f + 18.0f


			if (onCelling)
				if (tile.up != -1 && tileSet[tileMap.tiles[tile.up].tileIndex].kind == 2)
					let x : float = float(tile.x) * 64.0f

					if (x + 8.0f < pos.x && pos.x < x + 56.0f)
						tunnelTransitionType = TunnelTransitionType Up
						tunnelTransitionPos = -float(tile.y) * 64.0f - 64.0f - 18.0f

			if (tunnelTransitionType != TunnelTransitionType NotAvailable && get_key_down(VK_F))
				inTunnelTransition = true
				sndJump |> play_sound()

		if (abs(moveDir.x) > 0.01f)
			if (flipped != moveDir.x < -0.01f)
				tunnelTransitionType = TunnelTransitionType NotAvailable
			flipped = moveDir.x < -0.01f

		if (abs(moveDir.x) > 0.01f || (abs(moveDir.y) > 0.01f && onWall))
			if (!is_playing(sndRunInPlay))
				sndRunInPlay = play_sound_loop(sndRun, 1.0f)
		else
			if (is_playing(sndRunInPlay))
				stop_sound(sndRunInPlay)


		moveDir *= dt

		if (moveDir.x < 0.0f && tile.left != -1 && (tileSet[tileMap.tiles[tile.left].tileIndex].kind == 1 || (!inTunnelTransition && tileSet[tileMap.tiles[tile.left].tileIndex].kind != 0)))
			if (moveDir.x + pos.x - 18.0f <= float(tile.x * tileWidth))
				moveDir.x = 18.0f - pos.x + float(tile.x * tileWidth)

		if (moveDir.x > 0.0f && tile.right != -1 && (tileSet[tileMap.tiles[tile.right].tileIndex].kind == 1 || (!inTunnelTransition && tileSet[tileMap.tiles[tile.right].tileIndex].kind != 0)))
			if (moveDir.x + pos.x + 18.0f >= float((tile.x + 1) * tileWidth))
				moveDir.x = -18.0f - pos.x + float((tile.x + 1) * tileWidth)

		if (moveDir.y > 0.0f && tile.down != -1 && (tileSet[tileMap.tiles[tile.down].tileIndex].kind == 1 || (!inTunnelTransition && tileSet[tileMap.tiles[tile.down].tileIndex].kind != 0)))
			if (moveDir.y + pos.y + 18.0f >= -float((tile.y - 1) * tileHeight))
				moveDir.y = -18.0f - pos.y -float((tile.y - 1) * tileWidth)

		if (moveDir.y < 0.0f && tile.up != -1 && (tileSet[tileMap.tiles[tile.up].tileIndex].kind == 1 || (!inTunnelTransition && tileSet[tileMap.tiles[tile.up].tileIndex].kind != 0)))
			if (moveDir.y + pos.y - 18.0f < -float((tile.y) * tileHeight))
				moveDir.y = 18.0f - pos.y -float((tile.y) * tileWidth)

		pos += moveDir

		anim->Update(dt)

	def DrawIntroScene

		if (introStage >= 2)
			anim->Draw(pos, 0xFFFFFFFF, flipped, flippedV, 0.0f)

		animEgg->Draw(initPos + float2(0.0f, -20.0f), 0xFFFFFFFF, false, false, 0.0f)

		if (introStage == 0)
			introShadowWithP |> draw_image_transformed(cameraPos.x, cameraPos.y, float4(0.0f, 0.0f, 800.0f, 600.0f), 0xFFFFFFFF, float2(800.0f, 600.0f) / cameraZoom, 0.0f)
			animHeart->Draw(initPos + float2(0.0f, -10.0f), 0xFFFFFFFF, false, false, 0.0f)

		if (introStage == 1)
			let color : uint = introStage == 0 ? 0xFFFFFFFF : make_color(1.0f, 1.0f - introTimer)
			introShadow |> draw_image_transformed(cameraPos.x, cameraPos.y, float4(0.0f, 0.0f, 800.0f, 600.0f), color, float2(800.0f, 600.0f) / cameraZoom, 0.0f)
			animHeart->Draw(initPos + float2(0.0f, -10.0f), color, false, false, 0.0f)

		if (introStage == 3)
			var ps : float2 = screen_to_world(0.0f, 0.0f)
			fill_rect(int(ps.x), int(ps.y), 800, 600, 0x99000000)

			var sz : float2 = get_text_size("Happy birthday to me!!!")
			ps = screen_to_world(400.0f - sz.x * 0.5f, 280.0f)
			text_out(int(ps.x), int(ps.y), "Happy birthday to me!!!", 0xFF00FF00)

	def DrawSelectAbility
		if (!selectAbility)
			return

		var ps : float2 = screen_to_world(0.0f, 0.0f)
		fill_rect(int(ps.x), int(ps.y), 800, 600, 0x99000000)

		var sz : float2 = get_text_size("Select ability")
		ps = screen_to_world(400.0f - sz.x * 0.5f, 120.0f)
		
		text_out(int(ps.x), int(ps.y), "Select ability", 0xFFAA9F00)

		ps = screen_to_world(280.0f, 180.0f)
		text_out(int(ps.x), int(ps.y), abilities[abilitiesToSelect[0]].name, 0xFFAA9F00)

		ps = screen_to_world(220.0f, 175.0f)
		ui1 |> draw_image(int(ps.x), int(ps.y))

		if (length(abilitiesToSelect) > 1)
			ps = screen_to_world(280.0f, 230.0f)
			text_out(int(ps.x), int(ps.y), abilities[abilitiesToSelect[1]].name, 0xFFAA9F00)

			ps = screen_to_world(220.0f, 225.0f)
			ui2 |> draw_image(int(ps.x), int(ps.y))

		if (length(abilitiesToSelect) > 2)
			ps = screen_to_world(280.0f, 280.0f)
			text_out(int(ps.x), int(ps.y), abilities[abilitiesToSelect[2]].name, 0xFFAA9F00)

			ps = screen_to_world(220.0f, 275.0f)
			ui3 |> draw_image(int(ps.x), int(ps.y))

	def DrawUI

		if (killed)
			uiGameOver |> draw_image_transformed(cameraPos.x, cameraPos.y, float4(0.0f, 0.0f, 800.0f, 600.0f),  make_color(1.0f, deadAlpha), float2(800.0f, 600.0f) / cameraZoom, 0.0f)
		else
			if (stoneSkill < -0.5f)
				var ps : float2 = screen_to_world(0.0f, 537.0f)

				if (IsAbilityOpened(PlayerAbility  StoneSkin) && charges > 0)
					uiLeftOpened |> draw_image(int(ps.x), int(ps.y))
				else
					uiLeftClosed |> draw_image(int(ps.x), int(ps.y))
			else
				var ps : float2 = screen_to_world(0.0f, 537.0f)
				uiLeftClosed |> draw_image(int(ps.x), int(ps.y))

			if (IsAbilityOpened(PlayerAbility AcidShot) && !acidInUse && charges > 0 && inAcidShoot < -0.5f)
				var ps : float2 = screen_to_world(640.0f, 537.0f)
				uiRightOpened |> draw_image(int(ps.x), int(ps.y))
			else
				var ps : float2 = screen_to_world(695.0f, 537.0f)
				uiRightClosed |> draw_image(int(ps.x), int(ps.y))

			if (tunnelTransitionType != TunnelTransitionType NotAvailable && !inTunnelTransition)

				let tile = manager.tileMap.tiles[tileIndex]
				let x: float = float(tile.x) * 64.0f
				let y: float = -float(tile.y)* 64.0f

				if (tunnelTransitionType == TunnelTransitionType LeftRight)
					if (GetDirection() > 0.0f)
						uiFRight |> draw_image(x + 64.0f, y)
					else
						uiFLeft |> draw_image(x - 64.0f, y)
				elif (tunnelTransitionType == TunnelTransitionType Up)
					uiFUp |> draw_image(x, y - 64.0f)
				elif (tunnelTransitionType == TunnelTransitionType Down)
					uiFDown |> draw_image(x, y + 64.0f)


			if (pray != null)
				uiRDown |> draw_image(pray.pos.x - 32.0f, pray.pos.y - 150.0f)

			if (chargeTank != null && charges < NumChargeSlots())
				uiRPlus |> draw_image(chargeTank.pos.x - 32.0f, chargeTank.pos.y - 150.0f)

			if (NumChargeSlots() == 2)
				if (charges > 0)
					var ps : float2 = screen_to_world(336.0f, 540.0f)
					uiSlotCharged |> draw_image(int(ps.x), int(ps.y))
				else
					var ps : float2 = screen_to_world(336.0f, 540.0f)
					uiSlotEmpty |> draw_image(int(ps.x), int(ps.y))

				if (charges == 2)
					var ps : float2 = screen_to_world(410.0f, 540.0f)
					uiSlotCharged |> draw_image(int(ps.x), int(ps.y))
				else
					var ps : float2 = screen_to_world(410.0f, 540.0f)
					uiSlotEmpty |> draw_image(int(ps.x), int(ps.y))
			else
				if (charges == 1)
					var ps : float2 = screen_to_world(374.0f, 540.0f)
					uiSlotCharged |> draw_image(int(ps.x), int(ps.y))
				else
					var ps : float2 = screen_to_world(374.0f, 540.0f)
					uiSlotEmpty |> draw_image(int(ps.x), int(ps.y))

	def DrawOutro
		uiOutro |> draw_image_transformed(cameraPos.x, cameraPos.y, float4(0.0f, 0.0f, 800.0f, 600.0f), make_color(1.0f, deadAlpha), float2(800.0f, 600.0f) / cameraZoom, 0.0f)

	def override Draw

		if (inIntroScene)

			DrawIntroScene()

			return

		if (escaped)

			DrawOutro()

			return

		var angle = 0.0f

		if (onWall)
			angle = flipped ? PI : -PI

		if (flippedV)
			angle = -angle;

		if (acidInUse)
			acidImage |> draw_image_transformed(acidPos.x, acidPos.y, float4(0.0f, 0.0f, 32.0f, 34.0f), 0xFFFFFFFF, float2(32.0f * acidDir, 34.0f), 0.0f)

		anim->Draw(pos, stoneSkill > 0.01f ? 0xFF00FFFF : 0xFFFFFFFF, flipped, flippedV, angle * 0.5f)
		//circle(int(pos.x), int(pos.y), 14, 0xFFFFFF80)
		//var ps: float2 = screen_to_world(10.0f, 10.0f)
		//text_out(int(ps.x), int(ps.y), "{pos}", 0xFFAA9F00)

		DrawUI()

		DrawSelectAbility()
