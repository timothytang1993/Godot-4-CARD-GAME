extends Node

var battle_timer
var empty_monster_card_slots = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	battle_timer = $"../BattleTimer"
	battle_timer.one_shot = true
	battle_timer.wait_time = 1.0
	
	empty_monster_card_slots.append($"../CardSlots/EnemyCardSlot1")
	empty_monster_card_slots.append($"../CardSlots/EnemyCardSlot2")
	empty_monster_card_slots.append($"../CardSlots/EnemyCardSlot3")
	empty_monster_card_slots.append($"../CardSlots/EnemyCardSlot4")
	empty_monster_card_slots.append($"../CardSlots/EnemyCardSlot5")
	
func _on_end_turn_button_pressed() -> void:
	opponent_turn()
	
func opponent_turn():
	$"../EndTurnButton".disabled = true
	$"../EndTurnButton".visible = false
	
	# wait 1 second
	battle_timer.start()
	await battle_timer.timeout
	
	# if can draw card, draw than wait 1 seconds
	if $"../OpponentDeck".opponent_deck.size() != 0:
		$"../OpponentDeck".draw_card()
		# wait 1 second
		battle_timer.start()
		await battle_timer.timeout
	
	if empty_monster_card_slots.size() == 0:
		end_opponent_turn()
		return
		
	end_opponent_turn()
	
func end_opponent_turn():
	# reset player deck draw
	$"../EndTurnButton".disabled = false
	$"../EndTurnButton".visible = true
