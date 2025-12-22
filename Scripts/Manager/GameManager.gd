extends Node

signal game_level_changed(new_level: int)

var time_elapsed: float = 0.0
var score: int = 0
var enemyKilledInCurrentLevel: int = 0

var gameOver: bool = false
var isLevelEnd: bool = false

var gameLevel: int = 1
var maxLevelsBetweenUpgrades: int = 1 

var enemySpawner: EnemySpawner
var player: Player
var gameUI: GameUI
var pauseMenu: PauseMenu

func initVariable():
	player = get_tree().get_first_node_in_group("Player")
	enemySpawner = get_tree().get_first_node_in_group("EnemySpawner")
	gameUI = get_tree().get_first_node_in_group("GameUI")
	pauseMenu = get_tree().get_first_node_in_group("PauseMenu")
	if gameUI:
		gameUI.UpdateScore(score)
		gameUI.UpdateLevel(gameLevel)
	
func _process(delta: float) -> void:
	if !player || !enemySpawner || !gameUI:
		initVariable()
	if !gameOver:
		time_elapsed += delta
		if gameUI:
			gameUI.UpdateTimer(int(time_elapsed))
	else:
		pauseMenu.open_pause_menu()

func EndOfLevel() -> void:
	var enemies = get_tree().get_nodes_in_group("Enemy")
	if player && enemySpawner && enemies.is_empty():
		enemySpawner.StopSpawners()
		var levelUpMenu: MenuLevelUp = get_tree().get_first_node_in_group("LevelUpMenu")
		if levelUpMenu:
			levelUpMenu.showLevelUpMenu()
		else:
			StartNextLevel()


func StartNextLevel() -> void:
	gameLevel += 1
	game_level_changed.emit(gameLevel)
	enemyKilledInCurrentLevel = 0
	enemySpawner.currentEnemyNumber = 0
	enemySpawner.numberOfBoss = 0
	gameUI.UpdateLevel(gameLevel)
	gameUI.UpdateLevelProgression(enemyKilledInCurrentLevel,enemySpawner.spawnLimit)
	pauseMenu.UpdateProgressBars()
	
	enemySpawner.EnableMeleeSpawn()
	if enemySpawner && gameLevel >= 5:
		enemySpawner.EnableRangeSpawn()
	
	if gameUI && PlayerStatManager.isRangeUnlocked:
		print("GameManager unlock")
		gameUI.DisplayRangeIcon()
	if gameUI && PlayerStatManager.isAreaUnlocked:
		gameUI.DisplayAreeIcon()
	UpdateDifficulty()

func GetMaxEnemyToSpawn():
	if enemySpawner:
		return enemySpawner.spawnLimit
	else: 
		return 0

func UpdateScore(newScore):
	enemyKilledInCurrentLevel += 1
	score += newScore
	gameUI.UpdateScore(score)
	gameUI.UpdateLevelProgression(enemyKilledInCurrentLevel, enemySpawner.spawnLimit)

func UpdateDifficulty():
	GameDifficulty.UpdateMaxStats()
	GameDifficulty.IncreaseDifficulty(gameLevel)
	enemySpawner.spawnLimit = GameDifficulty.enemyCurrentSpawnLimit
	
func resetData() -> void:
	score = 0
	gameLevel = 1
	game_level_changed.emit(gameLevel)
	enemyKilledInCurrentLevel = 0
	time_elapsed = 0.0
	gameOver = false
	isLevelEnd = false
