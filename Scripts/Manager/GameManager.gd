extends Node

var score: int = 0
var gameOver: bool = false
var gameLevel: int = 1
var isLevelEnd: bool = false

var enemySpawner: EnemySpawner
var player: Player

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	enemySpawner = get_tree().get_first_node_in_group("EnemySpawner")

func EndOfLevel() -> void:
	var enemies = get_tree().get_nodes_in_group("Enemy")
	if player && enemySpawner && enemies.is_empty():
		print("ENDOFLEVEL")
		gameLevel += 1
		enemySpawner.currentEnemyNumber = 0
		UpdateDifficulty()

func UpdateDifficulty():
	GameDifficulty.UpdateMaxStats()
	GameDifficulty.IncreaseDifficulty(gameLevel)
	enemySpawner.spawnLimit = GameDifficulty.enemyCurrentSpawnLimit
	
func OnEnemyKilled(enemiesKilled: int):
	score += enemiesKilled
	UiManager.UpdateScore(score)
