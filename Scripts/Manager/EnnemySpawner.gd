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
@export var meleeEnemy: PackedScene = preload("res://Scenes/Enemy/MeleeEnemy.tscn")
@export var rangeEnemy: PackedScene = preload("res://Scenes/Enemy/RangeEnemy.tscn")
@export var bossEnemy: PackedScene = preload("res://Scenes/Enemy/BossEnemy.tscn")

var player: Player

# IMPORTANT : Changer pour faire spawn les enemies en dehors de la vue du joueur
var minSpawnDistance: float = -10.0
var maxSpawnDistance: float = 10.0

var numberOfBoss: int = 0


func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	if meleeEnemy == null:
		push_warning("EnemySpawner: 'meleeEnemy' n'est pas assigné (PackedScene null) -> fallback preload.")
		meleeEnemy = preload("res://Scenes/Enemy/MeleeEnemy.tscn")
	if rangeEnemy == null:
		push_warning("EnemySpawner: 'rangeEnemy' n'est pas assigné (PackedScene null) -> fallback preload.")
		rangeEnemy = preload("res://Scenes/Enemy/RangeEnemy.tscn")
	if bossEnemy == null:
		push_warning("EnemySpawner: 'bossEnemy' n'est pas assigné (PackedScene null) -> fallback preload.")
		bossEnemy = preload("res://Scenes/Enemy/BossEnemy.tscn")
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
			if bossEnemy == null:
				push_error("EnemySpawner.SpawnEnnemy: bossEnemy est null (PackedScene). Assigne une scène de boss dans l'inspecteur.")
				return
			var boss = bossEnemy.instantiate()
			boss.add_to_group("Enemy")
			add_child(boss)
			SpawnPosition(boss)
			return
		GameManager.EndOfLevel()
		return
	if ennemyToSpawn == null:
		push_error("EnemySpawner.SpawnEnnemy: ennemyToSpawn est null (PackedScene). Assigne la scène dans l'inspecteur (ex: RangeEnemy/MeleeEnemy).")
		return
	var enemy = ennemyToSpawn.instantiate()
	currentEnemyNumber += 1
	enemy.add_to_group("Enemy")
	add_child(enemy)
	SpawnPosition(enemy)

func StopSpawners():
	MeleeSpawnTimer.stop()
	RangeSpawnTimer.stop()
	BossSpawnTimer.stop()

func SpawnPosition(enemy: CharacterBody3D) -> void:
	if player && enemy is CharacterBody3D:
			var playerPos: Vector3 = (player.global_position)
			var x = randf_range(minSpawnDistance, maxSpawnDistance)
			var z = randf_range(minSpawnDistance, maxSpawnDistance)
			enemy.global_position = Vector3(x, 0.0 , z)
