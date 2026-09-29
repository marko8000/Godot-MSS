extends MSSLogic
class_name ChunkCalculator


enum Dimension {D0, D1, D2, D3}

@export var dim_data : Dictionary[Dimension, DimData]


func _ready() -> void:
	assert(Dimension.size() == dim_data.size(), 'Invalid dim_data')
	_setup_materials()


static func get_dim_from(node : Node) -> Dimension:
	if node is Node2D:
		return Dimension.D2
	elif node is Node3D:
		return Dimension.D3
	return Dimension.D0
	
	
static func get_zero(dimension : Dimension):
	match dimension:
		Dimension.D0:
			return 0
		Dimension.D1:
			return 0
		Dimension.D2:
			return Vector2.ZERO
		Dimension.D3:
			return Vector3.ZERO
	

func node_to_position(node : Node, dimension : Dimension) -> Variant:
	match dimension:
		Dimension.D1:
			var n : Node2D = node
			return n.position.x
		Dimension.D2:
			var n : Node2D = node
			return n.position
		Dimension.D3:
			var n : Node3D = node
			return n.position
	return
	

func position_to_chunk(position : Variant, dimension : Dimension) -> PackedInt64Array:
	var chunk_size := dim_data[dimension].chunk_size
	match dimension:
		Dimension.D1:
			var pos : int = position
			return [floori(pos / chunk_size)]
		Dimension.D2:
			var pos : Vector2i = position
			return [floori(pos.x / chunk_size), floori(pos.y / chunk_size)]
		Dimension.D3:
			var pos : Vector3i = position
			return [floori(pos.x / chunk_size), floori(pos.y / chunk_size), floori(pos.z / chunk_size)]
	return PackedInt64Array()


func get_chunks_around(chunk : PackedInt64Array) -> Array[PackedInt64Array]:
	var chunks : Array[PackedInt64Array]
	match chunk.size():
		Dimension.D0:
			pass
		Dimension.D1:
			chunk = get_1d_chunks_around(chunk)
		Dimension.D2:
			chunks = get_2dchunks_around(chunk)
		Dimension.D3:
			chunks = get_3dchunks_around(chunk)
	return chunks
	
	
func get_3dchunks_around(chunk : PackedInt64Array) -> Array[PackedInt64Array]:
	var draw_distance := dim_data[3].draw_distance
	var negative_chunk := PackedInt64Array([chunk[0]-draw_distance, chunk[1]-draw_distance, chunk[2]-draw_distance])
	var positive_chunk := PackedInt64Array([chunk[0]+draw_distance+1, chunk[1]+draw_distance+1, chunk[2]+draw_distance+1])
	var chunks : Array[PackedInt64Array]
	for x : int in range(negative_chunk[0], positive_chunk[0]):
		for y : int in range(negative_chunk[1], positive_chunk[1]):
			for z : int in range(negative_chunk[2], positive_chunk[2]):
				chunks.append([x, y, z])
	return chunks
	
	
func get_2dchunks_around(chunk : PackedInt64Array) -> Array[PackedInt64Array]:
	var draw_distance := dim_data[2].draw_distance
	var negative_chunk := PackedInt64Array([chunk[0]-draw_distance, chunk[1]-draw_distance])
	var positive_chunk := PackedInt64Array([chunk[0]+draw_distance+1, chunk[1]+draw_distance+1])
	var chunks : Array[PackedInt64Array]
	for x : int in range(negative_chunk[0], positive_chunk[0]):
		for y : int in range(negative_chunk[1], positive_chunk[1]):
			chunks.append([x, y])
	return chunks
	
	
func get_1d_chunks_around(chunk : PackedInt64Array) -> Array[PackedInt64Array]:
	var draw_distance := dim_data[2].draw_distance
	var negative_chunk := PackedInt64Array([chunk[0]-draw_distance])
	var positive_chunk := PackedInt64Array([chunk[0]+draw_distance+1])
	var chunks : Array[PackedInt64Array]
	for x : int in range(negative_chunk[0], positive_chunk[0]):
		chunks.append([x])
	return chunks
	
	
func visualize_chunk(chunk, color : String = '#ffffff'):
	if chunk is Vector4i:
		visualize3d(chunk)
		
		
func hide_chunk(chunk):
	if chunk is Vector3i:
		delete_if_exist('3d'+str(chunk))


var chunk_material = StandardMaterial3D.new()
func _setup_materials():
	chunk_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	chunk_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	chunk_material.cull_mode = BaseMaterial3D.CULL_DISABLED

# Function to visualize a chunk's borders
func visualize3d(chunk: Vector3i, color : String = '#ffffff'):
	if has_node('3d'+str(chunk)): return
	chunk_material.albedo_color = Color.html(color)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = create_chunk_wireframe_mesh(Vector3i.ONE * dim_data[3].chunk_size)
	mesh_instance.material_override = chunk_material
	mesh_instance.position = Vector3i(chunk.x, chunk.y, chunk.z) * dim_data[3].chunk_size
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
