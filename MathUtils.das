require daslib/math
require daslib/media

let Radian : float = 0.01745329f
var seedRandom: int4 = random_seed(777)

def GetRandom
	randomize_seed(seedRandom)
	return random_float(seedRandom)

def Cross(v1, v2: float2)
	return v1.x * v2.y - v1.y * v2.x

def IsPointInPolygon(pt: float2; polygon: array<float2>)

	let count: int = polygon |> length()

	var temp: array<float2>
	temp |> resize(count)

	for i in range(0, count)
		temp[i] = polygon[i] - pt

	let orientation: bool = Cross(temp[0], temp[1]) > 0.0f

	for i in range(0, count)
		if ((Cross(temp[i], temp[(i + 1) % count]) > 0.0f) != orientation)
			return false;

	return true
	
def IsPointInTriangle(pt, p1, p2, p3: float2)

	var polygon: array<float2>

	polygon |> push(p1)
	polygon |> push(p2)
	polygon |> push(p3)

	return IsPointInPolygon(pt, polygon)

def IsPointInSector(pt, center: float2; orientation, distance, angle : float)

	var side_angle : float = orientation - angle * 0.5f
	let p2: float2 = float2(cos(side_angle) * distance + center.x, sin(side_angle) * distance + center.y)

	side_angle = orientation + angle * 0.5f
	let p3: float2 = float2(cos(side_angle) * distance + center.x, sin(side_angle) * distance + center.y)

	return IsPointInTriangle(pt, center, p2, p3)