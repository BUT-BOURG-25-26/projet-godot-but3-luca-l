class_name InfiniteMapGenerator
extends Node3D

# IMPORTANT : class a refractor

@export var chunk_scenes: Array[PackedScene] 

@export var chunk_size: float = 50.0
@export var view_distance: int = 2

var loaded_chunks: Dictionary = {}
var player: Node3D

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	
	if chunk_scenes.is_empty():
		return
		
	update_chunks()

func _process(_delta: float) -> void:
	if !player:
		return
	update_chunks()

func update_chunks() -> void:
	var player_grid_x = round(player.global_position.x / chunk_size)
	var player_grid_z = round(player.global_position.z / chunk_size)
	var current_center = Vector2(player_grid_x, player_grid_z)
	
	var required_coords: Array[Vector2] = []
	
	for x in range(current_center.x - view_distance, current_center.x + view_distance + 1):
		for y in range(current_center.y - view_distance, current_center.y + view_distance + 1):
			required_coords.append(Vector2(x, y))
	
	var coords_to_remove: Array[Vector2] = []
	for coord in loaded_chunks.keys():
		if coord not in required_coords:
			loaded_chunks[coord].queue_free()
			coords_to_remove.append(coord)
	
	for coord in coords_to_remove:
		loaded_chunks.erase(coord)
	
	for coord in required_coords:
		if not loaded_chunks.has(coord):
			spawn_chunk(coord)

func spawn_chunk(coord: Vector2) -> void:
	var random_scene = chunk_scenes.pick_random()
	
	var new_chunk = random_scene.instantiate()
	add_child(new_chunk)
	
	new_chunk.global_position = Vector3(coord.x * chunk_size, 0, coord.y * chunk_size)
	
	loaded_chunks[coord] = new_chunk
