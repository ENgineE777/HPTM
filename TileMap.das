require daslib/media
require daslib/json
require daslib/json_boost
require daslib/json
require daslib/json_boost
require daslib/fio

let tileWidth = 64
let tileHeight = 64

struct TileDesc
    image: ImageHandle
    kind: int

struct Tile
	x: int
	y: int
	tileIndex: int
	data: int
	left: int = -1
	right: int = -1
	up: int = -1
	down: int = -1

var tileSet: array<TileDesc>

[export]
def InitTileSet()
	push(tileSet, [[TileDesc image=create_managed_image("Assets/Tiles/tile_01.png"), kind=1]])
	push(tileSet, [[TileDesc image=create_managed_image("Assets/Tiles/tile_03.png"), kind=0]])
	push(tileSet, [[TileDesc image=create_managed_image("Assets/Tiles/tile_02.png"), kind=1]])
	push(tileSet, [[TileDesc image=create_managed_image("Assets/Tiles/tile_05.png"), kind=2]])
	push(tileSet, [[TileDesc image=create_managed_image("Assets/Tiles/tile_04.png"), kind=3]])
	push(tileSet, [[TileDesc image=create_managed_image("Assets/Tiles/tile_06.png"), kind=0]])
	push(tileSet, [[TileDesc image=create_managed_image("Assets/Tiles/tile_07.png"), kind=0]])
	push(tileSet, [[TileDesc image=create_managed_image("Assets/Tiles/tile_08.png"), kind=0]])

class TileMap

	tiles: array<Tile>

	points2draw: array<float2>
	tempPoints: array<float2>

	resRayCast : array<float2>

	def Load(fileContent: string)

        var error : string
        var data = read_json(fileContent, error)

        if data == null || length(error) > 0 || !(data is _object)
           	return

		var entries <- data as _object

		var tilesArray <- entries["Tile"] as _array

		for tile in tilesArray
			var tileData <- tile as _object
			let x = int(tileData["x"] as _number)
			let y = int(tileData["y"] as _number)

			var texture <- tileData["Texture"] as _object
			let tileIndex = int(texture["sliceIndex"] as _number)
			tiles |> push([[Tile x=x, y=y, tileIndex=tileIndex]])

		for tile in tiles

			for index in range(0, length(tiles))

				var nextTile = tiles[index]

				if (tileSet[nextTile.tileIndex].kind == 1)
					if (tile.x == nextTile.x && tile.y == nextTile.y - 1)
						tile.data |= 1;
					elif (tile.x + 1 == nextTile.x && tile.y == nextTile.y)
						tile.data |= 2;
					elif (tile.x == nextTile.x && tile.y == nextTile.y + 1)
						tile.data |= 4;
					elif (tile.x - 1 == nextTile.x && tile.y == nextTile.y)
						tile.data |= 8;

				if (tile.x == nextTile.x && tile.y == nextTile.y - 1)
					tile.up = index;
				elif (tile.x + 1 == nextTile.x && tile.y == nextTile.y)
					tile.right = index;
				elif (tile.x == nextTile.x && tile.y == nextTile.y + 1)
					tile.down = index;
				elif (tile.x - 1 == nextTile.x && tile.y == nextTile.y)
					tile.left = index;

	def PositionToCell(pos: float2)
		var res: float2

		if (pos.x < 0.0f)
			res.x = float(int((pos.x - float(tileWidth))/ float(tileWidth)))
		else
			res.x = float(int((pos.x)/ float(tileWidth)))

		if (pos.y < 0.0f)
			res.y = -float(int((pos.y - float(tileHeight))/ float(tileHeight)))
		else
			res.y = -float(int((pos.y)/ float(tileHeight)))

		return res

	def FindTileIndex(pos: float2)

		let cell: float2 = PositionToCell(pos)

		let cellX: int = int(cell.x)
		let cellY: int = int(cell.y)

		for index in range(0, length(tiles))
			var tile = tiles[index]

			if (tile.x == cellX && tile.y == cellY)
				return index

		return -1

	def RayCast(p1, p2: float2; onlyWalls : bool)
		
		let cell1: float2 = PositionToCell(p1)
		let cell2: float2 = PositionToCell(p2)

		var x0, y0, x1, y1 : int
		
		x0 = int(cell1.x)
		y0 = int(cell1.y)

		x1 = int(cell2.x)
		y1 = int(cell2.y)

		resRayCast |> resize(0)

    	let steep: bool = abs(y1 - y0) > abs(x1 - x0)
    	
		if (steep)
			var tmp: int

			tmp = x0
			x0 = y0
			y0 = tmp

			tmp = x1
			x1 = y1
			y1 = tmp

    	if (x0 > x1)
			var tmp: int

			tmp = x0
			x0 = x1
			x1 = tmp

			tmp = y0
			y0 = y1
			y1 = tmp

    	let deltax: int = x1 - x0
    	let deltay: int = abs(y1 - y0)
    	var error: int = 0
    	var ystep: int = 0
    	var y: int = y0
    
		if (y0 < y1)
			ystep = 1
		else
			ystep = -1

		for x in range(x0, x1 + 1)

        	if (steep)
				resRayCast |> push(float2(y,x))
        	else
				resRayCast |> push(float2(x,y))
        
			error += deltay
        
			if (2 * error >= deltax)
            	y += ystep
            	error -= deltax

		for cell in resRayCast

			let cellX: int = int(cell.x)
			let cellY: int = int(cell.y)

			for i in range(0, length(tiles))
				var tile = tiles[i]

				if (tile.x == cellX && tile.y == cellY)
					if ((onlyWalls && tileSet[tile.tileIndex].kind == 1) ||
						(!onlyWalls && tileSet[tile.tileIndex].kind != 0))
						return true
						break

		return false

	def Draw(noCollision: bool)

		for tile in tiles
			let desc = tileSet[tile.tileIndex]

			if ((noCollision && desc.kind == 1) || (!noCollision && desc.kind != 1))
				continue

			/*var skip: bool = false;

			for cell in resRayCast
				if (tile.x == int(cell.x) && tile.y == int(cell.y))
					skip = true
					break

			if (skip)
				continue*/

        	let x = tile.x * tileWidth
			let y = tile.y * tileHeight

			desc.image |> draw_image(x, -y)

	def DrawShadow(pos: float2)

		for tile in tiles
			if (tileSet[tile.tileIndex].kind != 1)
				continue

			let x = float(tile.x * tileWidth)
			let y = -float(tile.y * tileHeight)

			if (x < pos.x - 64.0f * 20.0f || x > pos.x + 64.0f * 20.0f ||
				y < pos.y - 64.0f * 12.0f || y > pos.y + 64.0f * 12.0f)
				continue

			if (empty(tempPoints))
				tempPoints |> resize(4)

			tempPoints[0] = float2(x, y)
			tempPoints[1] = float2(x + float(tileWidth), y)
			tempPoints[2] = float2(x + float(tileWidth), y + float(tileHeight))
			tempPoints[3] = float2(x, y + float(tileHeight))

			if (empty(points2draw))
				points2draw |> resize(4)

			for index in range(0, 4)
				if ((tile.data & (1 << (index))) != 0)
					continue

				let p1 = tempPoints[(index + 1) % 4]
				let p2 = tempPoints[index]

				var dir = normalize(p2 - p1)

				var dir_to = normalize(p1 - pos)
				var dir_to2 = normalize(p2 - pos)

				points2draw[0] = p1
				points2draw[1] = p2
				points2draw[2] = p2 + dir_to2 * 900.0f
				points2draw[3] = p1 + dir_to * 900.0f

				fill_convex_polygon(points2draw, 0xB0000000)
