extends Node

var score: int = 0
var gameOver: bool = false
var isLevelEnd: bool = false

var gameLevel: int = 1
var maxLevelsBetweenUpgrades: int = 1 
var levelsToNextUpgrade: int = 0

var enemySpawner: EnemySpawner
var player: Player

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	enemySpawner = get_tree().get_first_node_in_group("EnemySpawner")
	SetNextUpgradeLevel()

func EndOfLevel() -> void:
	var enemies = get_tree().get_nodes_in_group("Enemy")
	if player && enemySpawner && enemies.is_empty():
		levelsToNextUpgrade -= 1
		print("ENDOFLEVEL: Niveau ", gameLevel, " terminé. Prochain menu dans ", levelsToNextUpgrade, " niveaux.")
		if levelsToNextUpgrade <= 0:
			var levelUpMenu: MenuLevelUp = get_tree().get_first_node_in_group("LevelUpMenu")
			if levelUpMenu:
				levelUpMenu.showLevelUpMenu()
			else:
				StartNextLevel()
		else:
			StartNextLevel()

func StartNextLevel() -> void:
	gameLevel += 1
	enemySpawner.currentEnemyNumber = 0
	
	if levelsToNextUpgrade <= 0:
		SetNextUpgradeLevel()
	
	UpdateDifficulty()

func SetNextUpgradeLevel():
	levelsToNextUpgrade = randi_range(2, maxLevelsBetweenUpgrades)

func UpdateDifficulty():
	GameDifficulty.UpdateMaxStats()
	GameDifficulty.IncreaseDifficulty(gameLevel)
	enemySpawner.spawnLimit = GameDifficulty.enemyCurrentSpawnLimit
	
func OnEnemyKilled(enemiesKilled: int):
	score += enemiesKilled
	UiManager.UpdateScore(score)
