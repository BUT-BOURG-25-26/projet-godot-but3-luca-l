extends Node
# IMPORTANT : REMPLACER ENSUITE PAR POURCENTAGE

# _______________LIMIT_______________
var enemyMaxSpawnLimit = 120

var meleeMinAttackTiming: float = 0.5
var meleeMaxHealth = 25
var meleeMaxMovementSpeed: float = 15
var meleeMaxDammage: int

var rangeMaxHealth = 20
var rangeMaxMovementSpeed: float = 10
var rangeMinAttackTiming: int = 0.5
var rangeMaxDammage: int

var bossMaxHealth = 30
var bossMaxMovementSpeed: float = 15
var bossMinAttackTiming: int = 0.5
var bossMaxDammage: int

# _______________Current stats_______________
var enemyCurrentSpawnLimit = 2

var meleeCurrentAttackTiming = 1.5
var meleeCurrentHealth = 1
var meleeCurrentMovementSpeed: float = 3
var meleeCurrentDammage: int = 1

var rangeCurrentHealth = 3
var rangeCurrentMovementSpeed: float = 2
var rangeCurrentAttackTiming: int = 1.5
var rangeCurrentDammage: int = 1

var bossCurrentHealth = 8
var bossCurrentMovementSpeed: float = 5
var bossCurrentAttackTiming: int = 1.5
var bossCurrentDammage: int = 1

func UpdateMaxStats():
	meleeMaxDammage = PlayerStatManager.playerMaxHealth * 0.25
	rangeMaxDammage = PlayerStatManager.playerMaxHealth * 0.25
	bossMaxDammage = PlayerStatManager.playerMaxHealth * 0.5

func UpdateCurrentStats():
	return

func IncreaseDifficulty(newLevel: int):
	if newLevel %2 == 0:
		IncreaseMeleeEnemyStats(newLevel)
		IncreaseRangeEnemyStats()
	elif newLevel %5 == 0:
		IncreaseBossEnemyStats()
	else:
		IncreaseSpawnLimit()

func IncreaseSpawnLimit():
	enemyCurrentSpawnLimit += randi_range(1,3)
	enemyCurrentSpawnLimit = clamp(enemyCurrentSpawnLimit, 5, enemyMaxSpawnLimit)
	print("new limit : " , enemyCurrentSpawnLimit)
	return

func IncreaseMeleeEnemyStats(newLevel: int):
	var randomValue = randi_range(0,3)
	if(randomValue == 0):
		meleeCurrentHealth += 2
		meleeCurrentHealth = clamp(meleeCurrentHealth, 0, meleeMaxHealth)
	elif randomValue == 1:
		meleeCurrentDammage += 2
		meleeCurrentDammage = clamp(meleeCurrentDammage, 0, meleeMaxDammage)
	elif randomValue == 2:
		meleeCurrentMovementSpeed += 2
		meleeCurrentMovementSpeed = clamp(meleeCurrentMovementSpeed, 0, meleeMaxMovementSpeed)	
	else:
		meleeCurrentAttackTiming -= 0.1
		meleeCurrentAttackTiming = clamp(meleeCurrentAttackTiming,meleeMinAttackTiming, 1.5)

func IncreaseRangeEnemyStats():
	return

func IncreaseBossEnemyStats():
	return
