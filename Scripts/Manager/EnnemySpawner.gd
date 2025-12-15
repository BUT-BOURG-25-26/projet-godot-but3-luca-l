class_name EnemySpawner
extends Node3D

# IMPORTANT : Mettre le spawnLimit dans GameManager plus tard
var spawnLimit: int = GameDifficulty.enemyCurrentSpawnLimit
var currentEnemyNumber: int = 0

#Timers
@export var MeleeSpawnTiming: float = 1.5
@onready var MeleeSpawnTimer: Timer = $Timers/MeleeSpawnTimer

@export var RangeSpawnTiming: float = 1.5
@onready var RangeSpawnTimer: Timer = $Timers/RangeSpawnTimer

@export var BossSpawnTiming: float = 1.5
@onready var BossSpawnTimer: Timer = $Timers/BossSpawnTimer

# Attack Scenes
@export var meleeEnemy: PackedScene
@export var rangeEnemy: PackedScene
@export var bossEnemy: PackedScene

var player: Player
# IMPORTANT : Changer pour faire spawn les enemies en dehors de la vue du joueur
var minSpawnDistance: float = -10.0
var maxSpawnDistance: float = 10.0

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	#MeleeSpawnTimer.start(MeleeSpawnTiming)
	#MeleeSpawnTimer.timeout.connect(SpawnEnnemy.bind(meleeEnemy))
	#
	#RangeSpawnTimer.start(RangeSpawnTiming)
	#RangeSpawnTimer.timeout.connect(SpawnEnnemy.bind(rangeEnemy))
	
	BossSpawnTimer.start(BossSpawnTiming)
	BossSpawnTimer.timeout.connect(SpawnEnnemy.bind(bossEnemy))
	

func SpawnEnnemy(ennemyToSpawn: PackedScene) -> void:
	if currentEnemyNumber >= spawnLimit:
		GameManager.EndOfLevel()
		return
	currentEnemyNumber += 1
	var enemy = ennemyToSpawn.instantiate()
	enemy.add_to_group("Enemy")
	add_child(enemy)
	SpawnPosition(enemy)

func SpawnPosition(enemy: CharacterBody3D) -> void:
	if player && enemy is CharacterBody3D:
			var playerPos: Vector3 = (player.global_position)
			var x = randf_range(minSpawnDistance, maxSpawnDistance)
			var z = randf_range(minSpawnDistance, maxSpawnDistance)
			enemy.global_position = Vector3(x, 0.0 , z)
