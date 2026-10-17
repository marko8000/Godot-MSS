extends RefCounted
class_name EntityWorker


var _EntityStorageLogic : EntityStorageLogic

var task_type : TaskType
var thread := Thread.new()
var running := true
enum TaskType {UPDATE_HOST, UPDATE_GUEST}
var buffer := StreamPeerBuffer.new()

class Task:
	var data : EntityStorageLogic.ChunkData
	var start_type : int
	var start_entity_i : int
	var end_type : int
	var end_entity_i : int


func _update() -> void:
	pass
