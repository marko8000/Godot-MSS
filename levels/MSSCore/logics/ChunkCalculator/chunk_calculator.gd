extends MSSLogic
class_name ChunkCalculator


@export var scale_levels : Array[ScaleLevel]


func get_zero(dimension : EntityFactory.EntityTypeData.Dimension):
	match dimension:
		EntityFactory.EntityTypeData.Dimension.V2:
			return Vector2.ZERO
		EntityFactory.EntityTypeData.Dimension.V3:
			return Vector3.ZERO
	
	
func position2d_to_chunk(position : Vector2, scale_level : int) -> Vector3i:
	var chunk_size := scale_levels[scale_level].chunk_size
	return Vector3i(floori(position.x / chunk_size), floori(position.y / chunk_size), scale_level)
	
	
func position3d_to_chunk(position : Vector3, scale_level : int) -> Vector4i:
	var chunk_size := scale_levels[scale_level].chunk_size
	return Vector4i(floori(position.x / chunk_size), floori(position.y / chunk_size), floori(position.z / chunk_size), scale_level)
		

func rotation_to_direction(rotation):
	if rotation is Vector3:
		return (Basis.from_euler(rotation) * Vector3.FORWARD).normalized()
	elif rotation is int:
		pass
	

func get_chunks_around(chunk : Variant) -> Array:
	if chunk is Vector4i:
		return get_3dchunks_around(chunk)
	elif chunk is Vector3i:
		return get_2dchunks_around(chunk)
	return []
	
	
func get_3dchunks_around(chunk : Vector4i) -> Array[Vector4i]:
	var draw_distance := scale_levels[chunk[-1]].chunk_size
	var negative_chunk = chunk - Vector4i(draw_distance, draw_distance, draw_distance, 0)
	var positive_chunk = chunk + Vector4i(draw_distance+1, draw_distance+1, draw_distance+1, 0)
	var chunks : Array[Vector4i]
	for x in range(negative_chunk.x, positive_chunk.x):
		for y in range(negative_chunk.y, positive_chunk.y):
			for z in range(negative_chunk.z, positive_chunk.z):
				chunks.append(Vector4i(x, y, z, chunk[-1]))
	return chunks
	
	
func get_2dchunks_around(chunk : Vector3i) -> Array[Vector3i]:
	var draw_distance := scale_levels[chunk[-1]].chunk_size
	var negative_chunk = chunk - Vector3i(draw_distance, draw_distance, 0)
	var positive_chunk = chunk + Vector3i(draw_distance+1, draw_distance+1, 0)
	var chunks : Array[Vector3i]
	for x in range(negative_chunk.x, positive_chunk.x):
		for y in range(negative_chunk.y, positive_chunk.y):
			chunks.append(Vector3i(x, y, chunk[-1]))
	return chunks
	
	
func visualize_chunk(chunk, color : String = '#ffffff'):
	if chunk is Vector4i:
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
func visualize3d(chunk: Vector4i, color : String = '#ffffff'):
	if has_node('3d'+str(chunk)): return
	chunk_material.albedo_color = Color.html(color)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = create_chunk_wireframe_mesh(Vector3i.ONE * scale_levels[chunk[-1]].chunk_size)
	mesh_instance.material_override = chunk_material
	mesh_instance.position = Vector3i(chunk.x, chunk.y, chunk.z) * scale_levels[chunk[-1]].chunk_size
	mesh_instance.name = '3d'+str(chunk)
	
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
	
	
# Utility function to clear all visualizations
func clear_visualizations():
	for child in get_children():
		child.queue_free()

func delete_if_exist(path : NodePath):
	if has_node(path):
		get_node(path).queue_free()
