extends Node
# IMPORTANT : REMPLACER ENSUITE PAR POURCENTAGE

# _______________LIMIT_______________
var playerMaxHealth: float = 100

var maxMeleeDammage: float = 25
var maxRangeDammage: float = 20
var maxAreaDammage: float = 10

var minMeleeAttackInterval: float = 0.5
var minRangeAttackInterval: float = 0.5
var minAreaAttackInterval: float = 0.5

var maxMovementSpeed: float = 25

# _______________Current stats_______________
var currentHealth: float = 5

var currentMeleeDammage: float = 1
var currentRangeDammage: float = 1
var currentAreaDammage: float = 1

var currentMeleeAttackInterval: float = 1.5
var currentRangeAttackInterval: float = 1.5
var currentAreaAttackInterval: float = 1.5

var currentMovementSpeed: float = 25

func IncreaseMeleeDamage(newLevel: int):
	return

func IncreaseRangeDamage():
	return

func IncreaseAreaDamage():
	return
	
func IncreaseHealth():
	return
	
func DecreaseMeleeAttackInterval():
	return

func DecreaseRangeAttackInterval():
	return

func DecreaseAreaAttackInterval():
	return
	
func IncreaseMovementSpeed():
	return
