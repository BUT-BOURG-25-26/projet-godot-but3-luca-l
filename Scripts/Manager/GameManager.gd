extends Node

var score: int = 0
var gameOver: bool = false
var isLevelEnd: bool = false

var gameLevel: int = 1
var maxLevelsBetweenUpgrades: int = 1 
var levelsToNextUpgrade: int = 0

var enemySpawner: EnemySpawner
var player: Player

const RANGE_ENEMY_START_LEVEL := 5
const BOSS_START_LEVEL := 10

@export var start_directly_at_range_wave: bool = false
@export var start_directly_at_boss_wave: bool = true

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	enemySpawner = get_tree().get_first_node_in_group("EnemySpawner")
	SetNextUpgradeLevel()
	# Defer to ensure EnemySpawner finished its own _ready().
	if start_directly_at_boss_wave:
		call_deferred("_start_at_boss_wave")
	elif start_directly_at_range_wave:
		call_deferred("_start_at_range_enemy_wave")


func _start_at_range_enemy_wave() -> void:
	if !start_directly_at_range_wave:
		return
	_initialize_game_at_level(RANGE_ENEMY_START_LEVEL)


func _start_at_boss_wave() -> void:
	if !start_directly_at_boss_wave:
		return
	_initialize_game_at_level(BOSS_START_LEVEL)


func _initialize_game_at_level(target_level: int) -> void:
	if enemySpawner == null:
		return
	gameLevel = max(1, target_level)

	# Approximate progression by applying difficulty steps up to the target level.
	GameDifficulty.UpdateMaxStats()
	for lvl in range(2, gameLevel + 1):
		GameDifficulty.IncreaseDifficulty(lvl)
	enemySpawner.spawnLimit = GameDifficulty.enemyCurrentSpawnLimit

	# Make sure spawners/timers are in the correct state for the starting level.
	enemySpawner.currentEnemyNumber = 0
	enemySpawner.numberOfBoss = 0
	enemySpawner.EnableMeleeSpawn()
	if gameLevel >= RANGE_ENEMY_START_LEVEL:
		enemySpawner.EnableRangeSpawn()
	# Le boss est géré par EnemySpawner quand le spawnLimit est atteint.

func EndOfLevel() -> void:
	var enemies = get_tree().get_nodes_in_group("Enemy")
	if player && enemySpawner && enemies.is_empty():
		enemySpawner.StopSpawners()
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
	enemySpawner.numberOfBoss = 0
	
	enemySpawner.EnableMeleeSpawn()
	if enemySpawner && gameLevel >= 5:
		enemySpawner.EnableRangeSpawn()
	
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
