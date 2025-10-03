extends VoxelTerrain


@export var library : Array[Texture2D]


func _ready() -> void:
	set_materials()
	
	
	
func set_materials():
	
	var textures : Array = get_transvoxel_textures()
	
	var texture_2d_array = Texture2DArray.new()
	texture_2d_array.create_from_images(convert_textures_to_one_format(textures))
	
	material_override.set('shader_parameter/u_texture_array', texture_2d_array)
	
	
func get_transvoxel_textures():
	var list : Array
	for texture in library:
		list.append(texture.get_image())
	return list
	
	
func convert_textures_to_one_format(textures):
	var converted_textures = []
	for img in textures:
		if img == null:
			push_error("Seems like someone didnt selected texture for transvoxel")
			return []
		var new_img = img.duplicate()
		if new_img.is_compressed():
			new_img.decompress()
		new_img.convert(Image.FORMAT_RGBA8)  # Or your desired format
		converted_textures.append(new_img)
	return converted_textures
