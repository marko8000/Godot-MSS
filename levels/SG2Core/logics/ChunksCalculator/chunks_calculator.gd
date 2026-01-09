@icon('res://levels/SG2Core/x_res/x_images/sg_logo.svg')
extends Node
## ChunksCalculator is used calculate equal virtual areas
class_name ChunksCalculator


@export var chunk_size : int = 64


# TERMS
# chunk_position : Vector = (position_of_smth - position_of_negative_position_of_chunk) 
# global_positon or position : Vector
# chunk : Vectori or null
# direction : Vectori


func position_to_chunk(position) -> Variant:
	if position is Vector3:
		return Vector3i(floor(position.x / chunk_size), floor(position.y / chunk_size), floor(position.z / chunk_size))
	elif position is Vector2:
		return Vector2i(floor(position.x / chunk_size), floor(position.y / chunk_size))
	return null
		
		
func rotation_to_direction(rotation):
	if rotation is Vector3:
		return (Basis.from_euler(rotation) * Vector3.FORWARD).normalized()
	elif rotation is int:
		pass
			

func dist(from, to) -> float:
	if from is Vector2i or from is Vector3i:
		return from.distance_to(to)
	return 0
		
		
func max_dist(current_chunk, drawing_distance: int) -> float:
	if current_chunk is Vector3i:
		return drawing_distance * sqrt(3)
	return 0
	
	
func get_chunks_around(current_chunk: Vector3i, drawing_distance: int) -> Array:
	if current_chunk is Vector3i:
		var negative_chunk := current_chunk - Vector3i(drawing_distance, drawing_distance, drawing_distance)
		var positive_chunk := current_chunk + Vector3i(drawing_distance+1, drawing_distance+1, drawing_distance+1)
		var chunks : Array[Vector3i]
		for x in range(negative_chunk.x, positive_chunk.x):
			for y in range(negative_chunk.y, positive_chunk.y):
				for z in range(negative_chunk.z, positive_chunk.z):
					chunks.append(Vector3i(x, y, z))
		return chunks
	return []
	
func visualize_chunk(chunk, color : String = '#ffffff'):
	if chunk is Vector3i:
		visualize3d(chunk)
		
		
func hide_chunk(chunk):
	if chunk is Vector3i:
		delete_if_exist('3d'+str(chunk))


var chunk_material = StandardMaterial3D.new()
func _ready():
	chunk_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	chunk_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	chunk_material.cull_mode = BaseMaterial3D.CULL_DISABLED

# Function to visualize a chunk's borders
func visualize3d(chunk_position: Vector3i, color : String = '#ffffff'):
	if has_node('3d'+str(chunk_position)): return
	chunk_material.albedo_color = Color.html(color)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = create_chunk_wireframe_mesh(Vector3(chunk_size, chunk_size, chunk_size))
	mesh_instance.material_override = chunk_material
	mesh_instance.position = chunk_position * Vector3i(chunk_size, chunk_size, chunk_size)
	mesh_instance.name = '3d'+str(chunk_position)
	
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
