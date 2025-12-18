extends Node

signal signalStatsUpdated

# _______________LIMIT_______________
var playerMaxHealth: float = 150

var maxMeleeDammage: float = 30
var maxRangeDammage: float = 20
var maxAreaDammage: float = 10

var minMeleeAttackInterval: float = 0.5
var minRangeAttackInterval: float = 0.3
var minAreaAttackInterval: float = 0.3

var maxMovementSpeed: float = 30

# _______________Current stats_______________
var currentHealth: float = 5

var currentMeleeDammage: float = 2
var currentRangeDammage: float = 1.5
var currentAreaDammage: float = 1

var currentMeleeAttackInterval: float = 1.5
var currentRangeAttackInterval: float = 2
var currentAreaAttackInterval: float = 1.75

var currentMovementSpeed: float = 5

var isRangeUnlocked: bool = false
var isAreaUnlocked: bool = false

# _______________Animation_______________
@onready var anim_player: AnimationPlayer = $AnimationPlayer

const MELEE_ANIM_NAME := "Attaque_melee"
# Pour calculer la vitesse d'anim en fonction de ton intervalle
var melee_anim_base_length := 0.0
# (recommandé) évite de relancer l'attaque si l'anim n'est pas finie
var is_melee_attacking := false

func IncreaseMeleeDamage(multiplier: float):
	currentMeleeDammage = clamp(currentMeleeDammage * (1.0 + multiplier), 0.0, maxMeleeDammage)

func IncreaseRangeDamage(multiplier: float):
	currentRangeDammage = clamp(currentRangeDammage * (1.0 + multiplier), 0.0, maxRangeDammage)

func IncreaseAreaDamage(multiplier: float):
	currentAreaDammage = clamp(currentAreaDammage * (1.0 + multiplier), 0.0, maxAreaDammage)

func IncreaseHealth(newHp: float):
	currentHealth = clamp(currentHealth + newHp, 0.0, playerMaxHealth)

func DecreaseMeleeAttackInterval(multiplier: float):
	currentMeleeAttackInterval = clamp(currentMeleeAttackInterval * (1.0 - multiplier), minMeleeAttackInterval, currentMeleeAttackInterval)

func DecreaseRangeAttackInterval(multiplier: float):
	currentRangeAttackInterval = clamp(currentRangeAttackInterval * (1.0 - multiplier), minRangeAttackInterval, currentRangeAttackInterval)

func DecreaseAreaAttackInterval(multiplier: float):
	currentAreaAttackInterval = clamp(currentAreaAttackInterval * (1.0 - multiplier), minAreaAttackInterval, currentAreaAttackInterval)

func IncreaseMovementSpeed(multiplier: float):
	currentMovementSpeed = clamp(currentMovementSpeed * (1.0 + multiplier), 0.0, maxMovementSpeed)



func is_melee_damage_max() -> bool:
	return currentMeleeDammage >= maxMeleeDammage

func is_range_damage_max() -> bool:
	return currentRangeDammage >= maxRangeDammage

func is_area_damage_max() -> bool:
	return currentAreaDammage >= maxAreaDammage

func is_movement_speed_max() -> bool:
	return currentMovementSpeed >= maxMovementSpeed

func is_melee_interval_min() -> bool:
	return currentMeleeAttackInterval <= minMeleeAttackInterval

func is_range_interval_min() -> bool:
	return currentRangeAttackInterval <= minRangeAttackInterval

func is_area_interval_min() -> bool:
	return currentAreaAttackInterval <= minAreaAttackInterval

func is_max_health_max() -> bool:
	return currentHealth >= playerMaxHealth

func UnlockRangeAttack():
	isRangeUnlocked = true
	GameManager.player.ActivateRangeAttack() 

func UnlockAreaAttack():
	isAreaUnlocked = true
	GameManager.player.ActivateAreaAttack()

func GetAvailableUpgrades() -> Array[String]:
	var availableUpgradeIds: Array[String] = []
	for key in PLAYER_UPGRADES.keys():
		availableUpgradeIds.append(key)
	
	var currentLevel = GameManager.gameLevel
	
	var i = availableUpgradeIds.size() - 1
	while i >= 0:
		var id = availableUpgradeIds[i]
		
		match id:
			"UPGRADE_MELEE_DMG":
				if is_melee_damage_max():
					availableUpgradeIds.remove_at(i)
			"UPGRADE_MOVE_SPEED":
				if is_movement_speed_max():
					availableUpgradeIds.remove_at(i)
			"UPGRADE_MELEE_ATTACK_SPEED":
				if is_melee_interval_min():
					availableUpgradeIds.remove_at(i)
			
			"UPGRADE_RANGE_DMG", "UPGRADE_RANGE_ATTACK_SPEED":
				if currentLevel < 5:
					availableUpgradeIds.remove_at(i)
				elif is_range_damage_max() and id == "UPGRADE_RANGE_DMG":
					availableUpgradeIds.remove_at(i)
				elif is_range_interval_min() and id == "UPGRADE_RANGE_ATTACK_SPEED":
					availableUpgradeIds.remove_at(i)
					
			"UPGRADE_AREA_DMG", "UPGRADE_AREA_ATTACK_SPEED":
				if currentLevel < 10:
					availableUpgradeIds.remove_at(i)
				elif is_area_damage_max() and id == "UPGRADE_AREA_DMG":
					availableUpgradeIds.remove_at(i)
				elif is_area_interval_min() and id == "UPGRADE_AREA_ATTACK_SPEED":
					availableUpgradeIds.remove_at(i)
			"UNLOCK_RANGE":
				if isRangeUnlocked || currentLevel < 5:
					availableUpgradeIds.remove_at(i)     
			"UNLOCK_AREA":
				if isAreaUnlocked ||currentLevel < 10:
					availableUpgradeIds.remove_at(i)
			_:
				pass
		i -= 1
	return availableUpgradeIds

func ApplyUpgrade(upgradeData: Dictionary) -> void:
	var type = upgradeData.type
	var value = upgradeData.value
	
	match type:
		"melee_damage_multiplier":
			IncreaseMeleeDamage(value)
		"range_damage_multiplier":
			IncreaseRangeDamage(value)
		"area_damage_multiplier":
			IncreaseAreaDamage(value)
		"max_health_flat":
			IncreaseHealth(value)
		"move_speed_multiplier":
			IncreaseMovementSpeed(value)
		"range_interval_multiplier":
			DecreaseRangeAttackInterval(value)
		"melee_interval_multiplier":
			DecreaseMeleeAttackInterval(value)
		"area_interval_multiplier":
			DecreaseAreaAttackInterval(value)
		"unlock_range":
			UnlockRangeAttack()
		"unlock_area":
			UnlockAreaAttack()
		_:
			push_warning("Upgrade inconnu : %s" % type)
	emit_signal("signalStatsUpdated")


func GetRandomUpgrades(count: int = 3) -> Array[Dictionary]:
	var allAvailableIds = GetAvailableUpgrades()
	var selectedIds = []
	
	var currentLevel = GameManager.gameLevel

	if currentLevel >= 10 && !isAreaUnlocked:
		selectedIds.append("UNLOCK_AREA")
		allAvailableIds.erase("UNLOCK_AREA")
	elif currentLevel >= 5 && !isRangeUnlocked:
		selectedIds.append("UNLOCK_RANGE")
		allAvailableIds.erase("UNLOCK_RANGE")


	allAvailableIds.shuffle()

	var requiredIds = count - selectedIds.size()
	
	for i in range(min(requiredIds, allAvailableIds.size())):
		selectedIds.append(allAvailableIds[i])

	var selectedUpgrades: Array[Dictionary] = []
	for id in selectedIds:
		var template = PLAYER_UPGRADES[id]
		var upgrade = GenerateUpgrade(id, template)
		selectedUpgrades.append(upgrade)

	selectedUpgrades.shuffle()
	return selectedUpgrades


func GenerateUpgrade(id: String, data: Dictionary) -> Dictionary:
	var randomValue
	
	match data.type:
		"max_health_flat":
			randomValue = randi_range(data.min, data.max)
		_:
			randomValue = randf_range(data.min, data.max)

	var displayValue = randomValue
	if data.type.ends_with("_multiplier"):
		displayValue = int(randomValue * 100)

	return {
		"id": id,
		"type": data.type,
		"value": randomValue,
		"name": data.name.format({
			"value": displayValue
		})
	}


const PLAYER_UPGRADES = {
	"UPGRADE_MELEE_DMG": {
		"name": "+{value}% Dégâts Mêlée", 
		"type": "melee_damage_multiplier",
		"min": 0.03,
		"max": 0.2,
	},
	"UPGRADE_RANGE_DMG": {
		"name": "+{value}% Dégâts à Distance", 
		"type": "range_damage_multiplier",
		"min": 0.03,
		"max": 0.2,
	},
	"UPGRADE_AREA_DMG": {
		"name": "+{value}% Dégâts de zone", 
		"type": "area_damage_multiplier",
		"min": 0.03,
		"max": 0.2,
	},
	"UPGRADE_MAX_HP": {
		"name": "+{value} PV Max",
		"type": "max_health_flat",
		"min": 2,
		"max": 10,
	},
	"UPGRADE_MOVE_SPEED": {
		"name": "+{value}% Vitesse",
		"type": "move_speed_multiplier",
		"min": 0.03,
		"max": 0.15,
	},
	"UPGRADE_RANGE_ATTACK_SPEED": {
		"name": "+{value}% Vitesse d'Attaque à Distance",
		"type": "range_interval_multiplier",
		"min": 0.03,
		"max": 0.2,
	},
	"UPGRADE_MELEE_ATTACK_SPEED": {
		"name": "+{value}% Vitesse d'Attaque mélée",
		"type": "melee_interval_multiplier",
		"min": 0.03,
		"max": 0.2,
	},
	"UPGRADE_AREA_ATTACK_SPEED": {
		"name": "+{value}% Vitesse d'Attaque de zone",
		"type": "area_interval_multiplier",
		"min": 0.03,
		"max": 0.2,
	},
	"UNLOCK_RANGE": {
		"name": "Débloquer l'Attaque à Distance",
		"type": "unlock_range",
		"min": 0,
		"max": 0,
		"value": 0,
	},
	"UNLOCK_AREA": {
		"name": "Débloquer l'Attaque de Zone",
		"type": "unlock_area",
		"min": 0,
		"max": 0,
		"value": 0,
	},
}
