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
		visualize_pixel3d(chunk)
		
		
func hide_chunk(chunk):
	if chunk is Vector2i:
		delete_if_exist('3d'+str(chunk))


var chunk_material = StandardMaterial3D.new()
func _ready():
	chunk_material.albedo_color = Color(1, 1, 1, 0.5)  # White with some transparency
	chunk_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	chunk_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	chunk_material.cull_mode = BaseMaterial3D.CULL_DISABLED

# Function to visualize a chunk's borders
func visualize_pixel3d(chunk_position: Vector2i):
	var _chunk_position = Vector3(chunk_position.x, 0, chunk_position.y)
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = create_chunk_wireframe_mesh(Vector3(chunk_size, chunk_size, chunk_size))
	mesh_instance.material_override = chunk_material
	mesh_instance.position = _chunk_position * Vector3(chunk_size, chunk_size, chunk_size)
	mesh_instance.name = '3d'+str(chunk_position)
	
	if not has_node(str(mesh_instance.name)):
		add_child(mesh_instance)
	return mesh_instance

func create_chunk_wireframe_mesh(size: Vector3) -> ArrayMesh:
	var st = SurfaceTool.new()
	var mesh = ArrayMesh.new()
	
	st.begin(Mesh.PRIMITIVE_LINES)
	
	# Define the 8 corners of the chunk
	var corners = [
		Vector3(0, 0, 0),
		Vector3(size.x, 0, 0),
		Vector3(0, size.y, 0),
		Vector3(size.x, size.y, 0),
		Vector3(0, 0, size.z),
		Vector3(size.x, 0, size.z),
		Vector3(0, size.y, size.z),
		Vector3(size.x, size.y, size.z)
	]
	
	# Define the 12 edges of the cube (pairs of corner indices)
	var edges = [
		[0, 1], [0, 2], [0, 4],  # Bottom edges
		[1, 3], [1, 5],          # Right edges
		[2, 3], [2, 6],          # Left edges
		[3, 7],                  # Top front edge
		[4, 5], [4, 6],          # Back edges
		[5, 7], [6, 7]           # Top back edges
	]
	
	# Add each edge as two vertices
	for edge in edges:
		st.add_vertex(corners[edge[0]])
		st.add_vertex(corners[edge[1]])
	
	# REMOVE THIS LINE: st.generate_normals()  # ← ERROR: Doesn't work with PRIMITIVE_LINES
	st.commit(mesh)
	return mesh
	
# Alternative: Simple ImmediateMesh version (less efficient but straightforward)
func visualize_simple(chunk_position: Vector3):
	var _chunk_size = Vector3(chunk_size, chunk_size*2, chunk_size)
	
	var mesh_instance = MeshInstance3D.new()
	var imesh = ImmediateMesh.new()
	var mesh = ArrayMesh.new()
	
	imesh.surface_begin(Mesh.PRIMITIVE_LINES, chunk_material)
	
	# Draw the 12 edges
	var min_pos = Vector3.ZERO
	var max_pos = _chunk_size
	
	# Bottom rectangle
	imesh.surface_add_vertex(min_pos)
	imesh.surface_add_vertex(Vector3(max_pos.x, min_pos.y, min_pos.z))
	
	imesh.surface_add_vertex(min_pos)
	imesh.surface_add_vertex(Vector3(min_pos.x, min_pos.y, max_pos.z))
	
	imesh.surface_add_vertex(Vector3(max_pos.x, min_pos.y, min_pos.z))
	imesh.surface_add_vertex(Vector3(max_pos.x, min_pos.y, max_pos.z))
	
	imesh.surface_add_vertex(Vector3(min_pos.x, min_pos.y, max_pos.z))
	imesh.surface_add_vertex(Vector3(max_pos.x, min_pos.y, max_pos.z))
	
	# Vertical edges
	for i in range(4):
		var base = [
			Vector3(min_pos.x, min_pos.y, min_pos.z),
			Vector3(max_pos.x, min_pos.y, min_pos.z),
			Vector3(min_pos.x, min_pos.y, max_pos.z),
			Vector3(max_pos.x, min_pos.y, max_pos.z)
		][i]
		
		imesh.surface_add_vertex(base)
		imesh.surface_add_vertex(Vector3(base.x, max_pos.y, base.z))
	
	# Top rectangle
	imesh.surface_add_vertex(Vector3(min_pos.x, max_pos.y, min_pos.z))
	imesh.surface_add_vertex(Vector3(max_pos.x, max_pos.y, min_pos.z))
	
	imesh.surface_add_vertex(Vector3(min_pos.x, max_pos.y, min_pos.z))
	imesh.surface_add_vertex(Vector3(min_pos.x, max_pos.y, max_pos.z))
	
	imesh.surface_add_vertex(Vector3(max_pos.x, max_pos.y, min_pos.z))
	imesh.surface_add_vertex(Vector3(max_pos.x, max_pos.y, max_pos.z))
	
	imesh.surface_add_vertex(Vector3(min_pos.x, max_pos.y, max_pos.z))
	imesh.surface_add_vertex(Vector3(max_pos.x, max_pos.y, max_pos.z))
	
	imesh.surface_end()
	mesh = imesh.commit()
	
	mesh_instance.mesh = mesh
	mesh_instance.material_override = chunk_material
	mesh_instance.position = chunk_position * _chunk_size
	
	add_child(mesh_instance)
	return mesh_instance

# Utility function to clear all visualizations
func clear_visualizations():
	for child in get_children():
		child.queue_free()

func delete_if_exist(path : NodePath):
	if has_node(path):
		get_node(path).queue_free()
