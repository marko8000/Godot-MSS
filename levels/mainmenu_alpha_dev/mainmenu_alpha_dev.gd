extends Control


var is_level

var last_page : String
var current_page : String


func _ready() -> void:
	pass
	
	change_page('MainPage')
	

func change_page(new_page : String):
	if has_node(new_page):
		last_page = current_page
		current_page = new_page
		get_node(current_page).show()
		if get_node(current_page).has_method('refresh'): get_node(current_page).refresh()
		if has_node(last_page):
			get_node(last_page).hide()
		
	
func _on_levels_pressed() -> void:
	change_page('LevelsPage')


func _on_timer_timeout() -> void:
	var rigid_body_instance = RigidBody3D.new()
	var ball_mesh = MeshInstance3D.new()
	ball_mesh.mesh = SphereMesh.new()
	ball_mesh.set_surface_override_material(0, StandardMaterial3D.new())
	ball_mesh.get_surface_override_material(0).albedo_texture = load('res://icon.svg')
	var ball_collision = CollisionShape3D.new()
	ball_collision.shape = SphereShape3D.new()
	rigid_body_instance.add_child(ball_mesh)
	rigid_body_instance.add_child(ball_collision)
	rigid_body_instance.position = Vector3(randf_range(-0.1, 0.1), 10, randf_range(-0.1, 0.1))
	$Node3D.add_child(rigid_body_instance)


func _on_servers_pressed() -> void:
	change_page('ServersPage')


func _on_timer_2_timeout() -> void:
	#print('hello', Dispenser.get_resource(self, '$Node3D/StaticBody3D/MeshInstance3D.surface_material_override/0.albedo_color'))
	#if $Node3D/StaticBody3D/MeshInstance3D.get_surface_override_material(0).albedo_color != Color(255, 255, 255, 255):
		#print(error_string(Dispenser.set_resource(self, '$Node3D/StaticBody3D/MeshInstance3D.surface_material_override/0.albedo_color', Color(255, 255, 255, 255))))
	#else:
		#print(error_string(Dispenser.set_resource(self, '$Node3D/StaticBody3D/MeshInstance3D.surface_material_override/0.albedo_color', Color(1, 1, 1, 1))))
	if $Node3D/StaticBody3D/MeshInstance3D.get_surface_override_material(0).albedo_color != Color(255, 255, 255, 255):
		Dispenser.set_resource(self, '$Node3D/StaticBody3D/MeshInstance3D.surface_material_override/0.albedo_color', Color(255, 255, 255, 255))
	else:
		Dispenser.set_resource(self, '$Node3D/StaticBody3D/MeshInstance3D.surface_material_override/0.albedo_color', Color(1, 1, 1, 1))
	#print(error_string(Dispenser.set_resource(self, 'position', Vector2(100, 100))))
	#print(error_string(Dispenser.set_resource($Node3D, 'position', Vector3(20, 2, 2))))
	#$Node3D/StaticBody3D.set('position', Vector3(20, 2, 2))
	#print('hello', Dispenser.get_resource(self, '$Node3D/StaticBody3D/MeshInstance3D.surface_material_override/0.albedo_color'))
