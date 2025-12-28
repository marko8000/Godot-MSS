@icon('res://levels/SG2Core/x_res/x_images/sg_logo.svg')
extends Node
## ChunksCalculator is used calculate equal virtual areas
class_name ChunksCalculator


@export var chunk_size : int = 16
@export var chunk_type : ChunkType = ChunkType.Pixel
enum ChunkType {
	## Vector2i chunk
	Pixel,
	## Vector3i chunk
	Voxel}


# TERMS
# chunk_position : Vector = (position_of_smth - position_of_negative_position_of_chunk) 
# global_positon or position : Vector
# chunk : Vectori or null
# direction : Vectori


func position_to_chunk(position) -> Variant:
	if chunk_type == ChunkType.Pixel:
		if position is Vector3:
			return Vector2i(floor(position.x / chunk_size), floor(position.z / chunk_size))
		elif position is Vector2:
			pass
	elif chunk_type == ChunkType.Voxel:
		if position is Vector3:
			pass
		elif position is Vector2:
			pass
	return null
		
		
func rotation_to_direction(rotation):
	if chunk_type == ChunkType.Pixel:
		if rotation is Vector3:
			return -Vector2i(round(sin(rotation.y)), round(cos(rotation.y)))
		elif rotation is Vector2:
			pass
	elif chunk_type == ChunkType.Pixel:
		if rotation is Vector3:
			pass
		elif rotation is Vector2:
			pass
				

func dist(chunk1, chunk2):
	if chunk1 is Vector2i or chunk1 is Vector3i:
		return chunk1.distance_to(chunk2)
	else:
		return 0
	
	
## CLEAR CACHE IF PLAYER_DIRECTION OR PLAYER_CHUNK HAS CHANGED
func chunks_in_front_of_player(player_chunk, player_direction, drawing_range = [0, 1], max_count_of_chunks = 1, cache = []):
	var chunks : Array
	var new_cache
	if player_chunk is Vector2i:
		new_cache = []
		var is_crooked_movement = false if abs(player_direction.x) + abs(player_direction.y) == 1 else true
		var right_side = Vector2i(-player_direction.y, player_direction.x)
		var left_side = Vector2i(player_direction.y, -player_direction.x)
		var crooks_dict = {Vector2i(1, -1): [Vector2i(0, 1), Vector2i(-1, 0)], 
							Vector2i(-1, -1): [Vector2i(1, 0), Vector2i(0, 1)], 
							Vector2i(-1, 1): [Vector2i(0, -1), Vector2i(1, 0)], 
							Vector2i(1, 1): [Vector2i(-1, 0), Vector2i(0, -1)]}
		var right_crook = crooks_dict[player_direction][0] if is_crooked_movement else null
		var left_crook = crooks_dict[player_direction][1] if is_crooked_movement else null
		var width_range = range(0, drawing_range[1]+2) if cache == [] else range(cache[0], drawing_range[1]+2)
		for width_level in width_range:
			var is_crooked_level = false if not is_crooked_movement or (is_crooked_movement and width_level % 2 != 0) else true
			if new_cache != []:
				break
			if width_level == 0:
				if cache != []:
					if cache[0] > 0:
						continue
				else:
					if drawing_range[0] > 0:
						continue
				if len(chunks)+1 > max_count_of_chunks and drawing_range[1] != 0:
					new_cache = [width_level, 0]
					continue
				chunks.append(player_chunk)
			elif width_level == 1:
				var length_range = range(drawing_range[0], drawing_range[1]+1) if drawing_range[0] != 0 else range(drawing_range[0]+1, drawing_range[1]+1)
				if cache != []:
					if width_level == cache[0]:
						length_range = range(cache[1], drawing_range[1]+1)
				for length in length_range:
					if len(chunks)+1 > max_count_of_chunks:
						new_cache = [width_level, length]
						break
					chunks.append(player_chunk + (player_direction * length))
			else:
				var length_range = range(drawing_range[0]-1-(drawing_range[0]-1), drawing_range[1]+1) if width_level > drawing_range[0] else range(drawing_range[0], drawing_range[1]+1)
				if cache != []:
					if width_level == cache[0]:
						length_range = range(cache[0]-2-(drawing_range[0]-1), drawing_range[1]+1) if width_level > drawing_range[0] else range(cache[0], drawing_range[1]+1)
				for length in length_range:
					if len(chunks)+2 > max_count_of_chunks:
						new_cache = [width_level, length]
						break
					if not is_crooked_level:
						if not is_crooked_movement:
							chunks.append(player_chunk + (right_side * (width_level-1)) + (player_direction * length))
							chunks.append(player_chunk + (left_side * (width_level-1)) + (player_direction * length))
						else:
							chunks.append(player_chunk + (right_side * ((width_level-1)/2)) + (player_direction * length))
							chunks.append(player_chunk + (left_side * ((width_level-1)/2)) + (player_direction * length))
					else:
						chunks.append(player_chunk + right_crook + (right_side * (width_level/2-1)) + (player_direction * length))
						chunks.append(player_chunk + left_crook + (left_side * (width_level/2-1)) + (player_direction * length))
	return [chunks, new_cache]
	
	
func visualize_chunk(chunk):
	if chunk is Vector2i:
		pass


func raise_if_wrong_chunk_type(chunk):
	var _type_of_chunk = typeof(chunk)
	var _chunk_types = [TYPE_VECTOR2I, TYPE_VECTOR3I, TYPE_VECTOR4I, TYPE_INT]
	assert(_type_of_chunk in _chunk_types, "Wrong chunk type")
