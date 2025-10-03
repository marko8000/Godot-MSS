@icon('res://levels/SG2Core/x_res/x_images/sg_logo.svg')
extends Node


const chunk_size : int = 16


# TERMS
# chunk_position : Vector = (position_of_smth - position_of_negative_position_of_chunk) 
# global_positon or position : Vector
# chunk : Vectori
# direction : Vectori


func position_to_chunk(position):
	var _type_of_position = typeof(position)
	
	if _type_of_position == TYPE_NIL:
		return 'unchunkable'
	elif _type_of_position == TYPE_VECTOR3:
		return Vector2i(floor(position.x / chunk_size), floor(position.z / chunk_size))
	elif _type_of_position == TYPE_VECTOR2:
		pass
	elif _type_of_position == TYPE_VECTOR4:
		pass
		
		
func position_to_chunk_position(position):
	return position - chunk_to_negative_chunk_position(position_to_chunk(position))
		
	
func chunk_to_negative_chunk_position(chunk):
	raise_if_wrong_chunk_type(chunk)
	var _type_of_chunk = typeof(chunk)
	
	if _type_of_chunk == TYPE_VECTOR2I:
		return Vector3(chunk.x * chunk_size, 0, chunk.y * chunk_size)
		
		
func chunk_position_to_position(chunk, chunk_position):
	raise_if_wrong_chunk_type(chunk)
	if str(chunk) == 'unchunkable':
		return chunk_position
		
	var _type_of_position = typeof(chunk_position)
	
	if _type_of_position == TYPE_VECTOR3:
		return chunk_to_negative_chunk_position(chunk) + chunk_position
	elif _type_of_position == TYPE_VECTOR2:
		pass
	elif _type_of_position == TYPE_VECTOR4:
		pass
		
		
func rotation_to_direction(rotation):
	var _type_of_rotation = typeof(rotation)
	
	if _type_of_rotation == TYPE_VECTOR3:
		return -Vector2i(round(sin(rotation.y)), round(cos(rotation.y)))
	elif _type_of_rotation == TYPE_VECTOR2:
		pass
	elif _type_of_rotation == TYPE_VECTOR4:
		pass
				

# PLEASE CLEAR CACHE IF PLAYER_DIRECTION HAS CHANGED
func chunks_in_front_of_player(player_chunk, player_direction, drawing_range = [0, 1], max_count_of_chunks = 1, cache = []):
	var chunks : Array
	var new_cache
	var type_of_player_chunk = typeof(player_chunk)
	if type_of_player_chunk == TYPE_VECTOR2I:
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


func raise_if_wrong_chunk_type(chunk):
	# raise_if_wrong_chunk(chunk)
	var _type_of_chunk = typeof(chunk)
	var _chunk_types = [TYPE_VECTOR2I, TYPE_VECTOR3I, TYPE_VECTOR4I, TYPE_INT]
	assert(_type_of_chunk in _chunk_types, "Wrong chunk type")
