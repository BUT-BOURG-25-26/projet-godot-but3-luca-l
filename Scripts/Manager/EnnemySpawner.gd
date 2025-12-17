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
var minSpawnRadius: float = 4.0 
var maxSpawnRadius: float = 12.0

var numberOfBoss: int = 0


func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	MeleeSpawnTimer.timeout.connect(SpawnEnnemy.bind(meleeEnemy))
	RangeSpawnTimer.timeout.connect(SpawnEnnemy.bind(rangeEnemy))
	EnableMeleeSpawn()

func EnableMeleeSpawn():
	if MeleeSpawnTimer.is_stopped():
		MeleeSpawnTimer.start(MeleeSpawnTiming)

func EnableRangeSpawn():
	if RangeSpawnTimer.is_stopped(): 
		RangeSpawnTimer.start(RangeSpawnTiming)

func SpawnEnnemy(ennemyToSpawn: PackedScene) -> void:
	if currentEnemyNumber >= spawnLimit:
		if numberOfBoss < GameManager.gameLevel / 10:
			numberOfBoss += 1
			var boss = bossEnemy.instantiate()
			boss.add_to_group("Enemy")
			add_child(boss)
			SpawnPosition(boss)
			return
		GameManager.EndOfLevel()
		return
	currentEnemyNumber += 1
	var enemy = ennemyToSpawn.instantiate()
	enemy.add_to_group("Enemy")
	add_child(enemy)
	SpawnPosition(enemy)

func StopSpawners():
	MeleeSpawnTimer.stop()
	RangeSpawnTimer.stop()
	BossSpawnTimer.stop()

func SpawnPosition(enemy: CharacterBody3D) -> void:
	if player and enemy is CharacterBody3D:
		var angle = randf() * TAU 

		var distance = randf_range(minSpawnRadius, maxSpawnRadius)

		var offset_x = cos(angle) * distance
		var offset_z = sin(angle) * distance

		var spawn_pos = player.global_position + Vector3(offset_x, 0.0, offset_z)
		
		enemy.global_position = spawn_pos
		enemy.look_at(player.global_position, Vector3.UP)
