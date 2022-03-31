require daslib/math
require MathUtils
require TileMap
require Character
require daslib/media
require daslib/json
require daslib/json_boost
require daslib/fio

var manager: WorldManager?

class WorldManager

	player: Character?
	soldiers: array<Character?>
	chargeTanks: array<Character?>
	turrets: array<Character?>
	hearts: array<Character?>

	tileMap : TileMap?

	createSoldier : function<():Character?>
	createChargeTank : function<():Character?>
	createTurret : function<():Character?>
	createHeart : function<():Character?>

	exitPos : float2

	def Init(setCreatePlayer : function<():Character?>; setCreateSoldier : function<():Character?>;
			 setCreateChargeTank : function<():Character?>; setCreateTurret : function<():Character?>;
			 setCreateHeart: function<():Character?>)
		
		InitTileSet()

		player = invoke(setCreatePlayer)
		player->Init()

		createSoldier = setCreateSoldier
		createChargeTank = setCreateChargeTank
		createTurret = setCreateTurret
		createHeart = setCreateHeart

	def LoadZone(fileName:string)

		var file : FILE const? = fopen(fileName, "rb")
		var fileContent : string = fread(file)

        var error : string
        var jsonData = read_json(fileContent, error)

        if jsonData == null || length(error) > 0 || !(jsonData is _object)
           	return

        var entries <- jsonData as _object

    	player.initPos = float2(entries["PlayerPosX"] as _number, entries["PlayerPosY"] as _number)

		exitPos = float2(entries["ExitPosX"] as _number, entries["ExitPosY"] as _number)

		tileMap = new TileMap()
    	tileMap->Load(fileContent)

		var soldiersArray <- entries["Soldiers"] as _array
		soldiers |> resize(length(soldiersArray))

		for i in range(0, length(soldiersArray))

			var data <- soldiersArray[i] as _object

			soldiers[i] = invoke(createSoldier)
			soldiers[i].initPos = float2(data["x"] as _number, data["y"] as _number)
    		soldiers[i]->SetLimits(float(data["left"] as _number), float(data["right"] as _number))

		var chargeTanksArray <- entries["ChargeTanks"] as _array
		chargeTanks |> resize(length(chargeTanksArray))

		for i in range(0, length(chargeTanksArray))

			var data <- chargeTanksArray[i] as _object

			chargeTanks[i] = invoke(createChargeTank)
			chargeTanks[i].initPos = float2(data["x"] as _number, data["y"] as _number)

		var turretsArray <- entries["Turrets"] as _array
		turrets |> resize(length(turretsArray))

		for i in range(0, length(turretsArray))

			var data <- turretsArray[i] as _object

			turrets[i] = invoke(createTurret)
			turrets[i].initPos = float2(data["x"] as _number, data["y"] as _number)
    		turrets[i]->SetLimits(float(data["left"] as _number), float(data["right"] as _number))


		var heartsArray <- entries["Hearts"] as _array
		hearts |> resize(length(heartsArray))

		for i in range(0, length(heartsArray))

			var data <- heartsArray[i] as _object

			hearts[i] = invoke(createHeart)
			hearts[i].initPos = float2(data["x"] as _number, data["y"] as _number)

		Reset()

	def Reset
		player->Reset()

		for soldier in soldiers
        	soldier->Reset()

		for turret in turrets
        	turret->Reset()

		for chargeTank in chargeTanks
        	chargeTank->Reset()

		for heart in hearts
        	heart->Reset()

	def Update(dt:float)

	    player->Update(dt)

		for chargeTank in chargeTanks
        	chargeTank->Update(dt)

		for turret in turrets
        	turret->Update(dt)

    	for soldier in soldiers
        	soldier->Update(dt)

		for heart in hearts
        	heart->Update(dt)

	def Draw
	    tileMap->Draw(true)

		for chargeTank in chargeTanks
        	chargeTank->Draw()

		for turret in turrets
        	turret->Draw()

		for heart in hearts
        	heart->Draw()

    	for soldier in soldiers
        	soldier->Draw()

    	tileMap->DrawShadow(player.pos)

		for soldier in soldiers
        	soldier->DrawOverShadow()

    	tileMap->Draw(false)

    	player->Draw()

	def KillPlayer
		player->Kill()

	def IsPlayerHasHeartSensor
		return player->HasHeartSensor()

	def PlayerHaveReachedEscape

		var pos: float2 = player.pos

		if (exitPos.x - 32.0f < pos.x && pos.x < exitPos.x + 32.0f &&
			exitPos.y - 32.0f < pos.y && pos.y < exitPos.y + 32.0f)
			return true

		return false

	def TryGrabHeart
	
		var pos: float2 = player.pos

		for heart in hearts
			if (heart.killed)
				continue

			var targetPos: float2 = heart.pos
	
			if (targetPos.x - 15.0f < pos.x && pos.x < targetPos.x + 15.0f &&
				targetPos.y - 25.0f < pos.y && pos.y < targetPos.y + 35.0f)
				heart->Kill()
				return true

		return false

	def FindDeadFromAboveVictim

		var pos: float2 = player.pos

		for soldier in soldiers
			if (soldier.killed)
				continue

			var targetPos: float2 = soldier.pos
	
			if (pos.x - 48.0f < targetPos.x && targetPos.x < pos.x + 48.0f &&
				pos.y < targetPos.y && targetPos.y < pos.y + 300.0f)
				return soldier

		return null

	def FindAttackVictim(pos: float2)

		for soldier in soldiers
			if (soldier.killed)
				continue

			var targetPos: float2 = soldier.pos
	
			if (targetPos.x - 32.0f < pos.x && pos.x < targetPos.x + 32.0f &&
				targetPos.y - 72.0f < pos.y && pos.y < targetPos.y)
				return soldier

		return null

	def FindPlayerAttackVictim

		return FindAttackVictim(player.pos)

	def FindChargeTank

		var pos: float2 = player.pos

		for chargeTank in chargeTanks
			if (chargeTank.killed)
				continue

			var targetPos: float2 = chargeTank.pos
	
			if (targetPos.x - 32.0f < pos.x && pos.x < targetPos.x + 32.0f &&
				targetPos.y - 90.0f < pos.y && pos.y < targetPos.y)
				return chargeTank

		return null

	def IsPlayerVisibleInSector(pos: float2; dist:float; angle: float; checkRadius: bool)

		if (player.killed)
			return false

		var targetPos: float2 = player.pos

		var dir: float2 = targetPos - pos

		var res: bool = false

		if (checkRadius && length_sq(dir) < 120.0f * 120.0f)
			res = true

		if (!res)
			res = IsPointInSector(targetPos, pos, angle * Radian, dist, 45.0f * Radian)

		return res && !tileMap->RayCast(targetPos, pos, false)

	def IsVisibleByPlayer(pos: float2)

		var targetPos: float2 = player.pos

		var dir: float2 = targetPos - pos

		if (length_sq(dir) < 850.0f * 850.0f && !tileMap->RayCast(targetPos, pos, true))
			return true

		return false

	def GetDistToPlayer(pos: float2)

		var targetPos: float2 = player.pos

		let dir: float2 = targetPos - pos

		return length(dir)

	def GetAngleToPlayer(pos: float2)

		var targetPos: float2 = player.pos

		let dir: float2 = targetPos - pos

		return atan2(dir.y, abs(dir.x)) / Radian

	def GetDirectionToPlayer(pos: float2)

		let dir: float2 = player.pos - pos

		return dir.x < 0.0f ? -1.0f : 1.0f