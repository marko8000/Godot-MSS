extends MSSLogic
class_name ChunkCalculator


const MAX_SCALE_LEVEL := 254
const UNUSED_SCALE_LEVEL := MAX_SCALE_LEVEL+1
const MAX_LOD := 254
const UNUSED_LOD := MAX_LOD+1
enum ScaleLevelLabel {
	NORMAL
	}
var scale_levels : Dictionary[ScaleLevelLabel, ScaleLevel] = {
	ScaleLevelLabel.NORMAL: ScaleLevel.new(16, [1, 2, 3])
	}
var scale_level_order : Array[int] = [
	ScaleLevelLabel.NORMAL
	]
@warning_ignore("unused_private_class_variable")
@onready var _scale_levels_by_size := _sort_levels_by_size()

enum Dimension {D0, D1, D2, D3}

@export var dim_data : Dictionary[Dimension, DimData]


func _sort_levels_by_size() -> Array[int]:
	var sorted : Array[int]
	for label : int in scale_level_order:
		sorted.append(label)
	return sorted
	
	
func _ready() -> void:
	for data : DimData in dim_data.values():
		data.storage = get_node(data.storage_path)
	assert(Dimension.size() == dim_data.size(), 'Invalid dim_data')
	_setup_materials()


func get_dim_from(node : Node) -> Dimension:
	if node is Node2D:
		return Dimension.D2
	elif node is Node3D:
		return Dimension.D3
	return Dimension.D0
	
	
func get_zero(dimension : Dimension):
	match dimension:
		Dimension.D0:
			return 0
		Dimension.D1:
			return 0
		Dimension.D2:
			return Vector2.ZERO
		Dimension.D3:
			return Vector3.ZERO
	
	
func position_to_chunk(root_parent_idx : int, scale_level_idx : int, root_position : Variant, dimension : int) -> PackedInt64Array:
	var scale_level := scale_level_order[scale_level_idx]
	var chunk_size := scale_levels[scale_level].chunk_size
	var chunk : PackedInt64Array
	chunk.resize(2+dimension)
	chunk[0] = root_parent_idx
	chunk[1] = scale_level_idx
	for i in range(2, dimension+2):
		chunk[i] = floori(root_position[i-2]/chunk_size)
	return chunk
		

func rotation_to_direction(rotation):
	if rotation is Vector3:
		return (Basis.from_euler(rotation) * Vector3.FORWARD).normalized()
	elif rotation is int:
		pass


func get_chunks_around(chunk : PackedInt64Array) -> Array[PackedInt64Array]:
	var draw_distance := scale_levels[_scale_levels_by_size[chunk[0]]].chunk_size
	var negative : PackedInt64Array
	var positive : PackedInt64Array
	for i in range(2, chunk.size()):
		negative[i] = chunk[i] - draw_distance
		positive[i] = chunk[i] + draw_distance+1
		
	return []
	
	
func get_3dchunks_around(chunk : Vector4i) -> Array[Vector4i]:
	var draw_distance := scale_levels[chunk.x].chunk_size
	var negative_chunk = chunk - Vector4i(0, draw_distance, draw_distance, draw_distance)
	var positive_chunk = chunk + Vector4i(0, draw_distance+1, draw_distance+1, draw_distance+1)
	var chunks : Array[Vector4i]
	for x in range(negative_chunk.y, positive_chunk.y):
		for y in range(negative_chunk.z, positive_chunk.z):
			for z in range(negative_chunk.w, positive_chunk.w):
				chunks.append(Vector4i(chunk.x, x, y, z))
	return chunks
	
	
func get_2dchunks_around(chunk : Vector3i) -> Array[Vector3i]:
	var draw_distance := scale_levels[chunk.x].chunk_size
	var negative_chunk = chunk - Vector3i(0, draw_distance, draw_distance)
	var positive_chunk = chunk + Vector3i(0, draw_distance+1, draw_distance+1)
	var chunks : Array[Vector3i]
	for x in range(negative_chunk.y, positive_chunk.y):
		for y in range(negative_chunk.z, positive_chunk.z):
			chunks.append(Vector3i(chunk.x, x, y))
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
func visualize3d(chunk: Vector4i, color : String = '#ffffff'):
	if has_node('3d'+str(chunk)): return
	chunk_material.albedo_color = Color.html(color)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = create_chunk_wireframe_mesh(Vector3i.ONE * scale_levels[chunk.x].chunk_size)
	mesh_instance.material_override = chunk_material
	mesh_instance.position = Vector3i(chunk.y, chunk.z, chunk.w) * scale_levels[chunk.x].chunk_size
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
