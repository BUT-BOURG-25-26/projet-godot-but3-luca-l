extends Node
# IMPORTANT : REMPLACER ENSUITE PAR POURCENTAGE

# _______________LIMIT_______________
var enemyMaxSpawnLimit = 500

var meleeMinAttackTiming: float = 0.25
var meleeMaxHealth = 75
var meleeMaxMovementSpeed: float = 25
var meleeMaxDammage: float

var rangeMaxHealth = 50
var rangeMaxMovementSpeed: float = 20
var rangeMinAttackTiming: float = 0.5
var rangeMaxDammage: float
var rangeMaxProjectilSpeed: float = 15

var bossMaxHealth = 125
var bossMaxMovementSpeed: float = 25
var bossMinAttackTiming: float = 0.25
var bossMaxDammage: float

# _______________Current stats_______________
var enemyCurrentSpawnLimit = 1

var meleeCurrentHealth = 3
var meleeCurrentMovementSpeed: float = 3
var meleeCurrentAttackTiming: float = 1.75
var meleeCurrentDammage: float = 1

var rangeCurrentHealth = 2
var rangeCurrentMovementSpeed: float = 2
var rangeCurrentAttackTiming: float = 1.5
var rangeCurrentDammage: float = 1
var rangeCurrentProjectilSpeed: float = 5

var bossCurrentHealth = 8
var bossCurrentMovementSpeed: float = 5
var bossCurrentAttackTiming: float = 1.5
var bossCurrentDammage: float = 1

func UpdateMaxStats():
	meleeMaxDammage = PlayerStatManager.playerMaxHealth * 0.25
	rangeMaxDammage = PlayerStatManager.playerMaxHealth * 0.15
	bossMaxDammage = PlayerStatManager.playerMaxHealth * 0.45

func IncreaseDifficulty(newLevel: int):
	UpdateMaxStats()
	if newLevel %2 == 0:
		IncreaseMeleeEnemyStats(newLevel)
		IncreaseRangeEnemyStats()
	elif newLevel %5 == 0:
		IncreaseBossEnemyStats()
	elif newLevel %3 == 0:
		IncreaseSpawnLimit()

func IncreaseSpawnLimit():
	enemyCurrentSpawnLimit += randi_range(1,3)
	enemyCurrentSpawnLimit = clamp(enemyCurrentSpawnLimit, 5, enemyMaxSpawnLimit)
	print("NEW Spawn Limit : " , enemyCurrentSpawnLimit)
	return

func IncreaseMeleeEnemyStats(newLevel: int):
	var randomValue = randi_range(0,3)
	const GROWTH_MULTIPLIER = 1.2
	const TIMING_REDUCTION = 0.9
	
	if(randomValue == 0):
		meleeCurrentHealth *= GROWTH_MULTIPLIER
		meleeCurrentHealth = clamp(meleeCurrentHealth, 0, meleeMaxHealth)
	elif randomValue == 1:
		meleeCurrentDammage *= GROWTH_MULTIPLIER
		meleeCurrentDammage = clamp(meleeCurrentDammage, 0, meleeMaxDammage)
	elif randomValue == 2:
		meleeCurrentMovementSpeed *= GROWTH_MULTIPLIER
		meleeCurrentMovementSpeed = clamp(meleeCurrentMovementSpeed, 0, meleeMaxMovementSpeed)	
	else:
		meleeCurrentAttackTiming *= TIMING_REDUCTION
		meleeCurrentAttackTiming = clamp(meleeCurrentAttackTiming,meleeMinAttackTiming, 1.5)
	print("[MeleeEnemy]: ", "currentPV: ", meleeCurrentHealth, " |movespeed: ", meleeCurrentMovementSpeed, " |damage: ", meleeCurrentDammage, " |tinterval: ", meleeCurrentAttackTiming)

func IncreaseRangeEnemyStats():
	var randomValue = randi_range(0, 3)
	const GROWTH_MULTIPLIER = 1.2
	const TIMING_REDUCTION = 0.88
	
	if randomValue == 0:
		rangeCurrentHealth *= GROWTH_MULTIPLIER
		rangeCurrentHealth = clamp(rangeCurrentHealth, 0, rangeMaxHealth)
	elif randomValue == 1:
		rangeCurrentDammage *= GROWTH_MULTIPLIER
		rangeCurrentDammage = clamp(rangeCurrentDammage, 0, rangeMaxDammage)
	elif randomValue == 2:
		rangeCurrentMovementSpeed *= GROWTH_MULTIPLIER
		rangeCurrentMovementSpeed = clamp(rangeCurrentMovementSpeed, 0, rangeMaxMovementSpeed)
		
		rangeCurrentProjectilSpeed *= GROWTH_MULTIPLIER
		rangeCurrentProjectilSpeed = clamp(rangeCurrentProjectilSpeed, 0, rangeMaxProjectilSpeed)
	else:
		rangeCurrentAttackTiming *= TIMING_REDUCTION 
		rangeCurrentAttackTiming = clamp(rangeCurrentAttackTiming, rangeMinAttackTiming, 1.5)


func IncreaseBossEnemyStats():
	var randomValue = randi_range(0, 3)
	const GROWTH_MULTIPLIER = 1.25
	const TIMING_REDUCTION = 0.85
	
	if randomValue == 0:
		bossCurrentHealth *= GROWTH_MULTIPLIER
		bossCurrentHealth = clamp(bossCurrentHealth, 0, bossMaxHealth)
	elif randomValue == 1:
		bossCurrentDammage *= GROWTH_MULTIPLIER
		bossCurrentDammage = clamp(bossCurrentDammage, 0, bossMaxDammage)
	elif randomValue == 2:
		bossCurrentMovementSpeed *= 1.1 
		bossCurrentMovementSpeed = clamp(bossCurrentMovementSpeed, 0, bossMaxMovementSpeed)	
	else:
		bossCurrentAttackTiming *= TIMING_REDUCTION
		bossCurrentAttackTiming = clamp(bossCurrentAttackTiming, bossMinAttackTiming, 1.5)
