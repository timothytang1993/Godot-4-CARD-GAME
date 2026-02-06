extends Node

const SMALL_CARD_SCALE = 0.3
const CARD_MOVE_SPEED = 0.2

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
		
	# try play card and wait 1 sec if played
	await try_play_card_with_highest_attack()
	
	end_opponent_turn()

func try_play_card_with_highest_attack():
	# Check if any card is in hand
	var opponent_hand = $"../OpponentHand".opponent_hand
	if opponent_hand.size() == 0:
		end_opponent_turn()
		return
	
	# Get random empty slot to play the card in
	var random_empty_monster_card_slot = empty_monster_card_slots[
		randi_range(0, empty_monster_card_slots.size()-1)]
	empty_monster_card_slots.erase(random_empty_monster_card_slot)
	
	# Play the card in hand with  highest attack
	# Start by assuming the first card in hand has highest attack
	var card_with_highest_atk = opponent_hand[0]
	# Loop through cards in hand looking for higher attack
	for card in opponent_hand:
		if card.attack > card_with_highest_atk.attack:
			card_with_highest_atk = card
	
	# Animate card to position
	var tween = get_tree().create_tween()
	tween.tween_property(card_with_highest_atk, "position", random_empty_monster_card_slot.position, CARD_MOVE_SPEED)
	var tween2 = get_tree().create_tween()
	tween2.tween_property(card_with_highest_atk, "scale", Vector2(SMALL_CARD_SCALE, SMALL_CARD_SCALE), CARD_MOVE_SPEED)
	card_with_highest_atk.get_node("AnimationPlayer").play("card_flip")
	
	# Remove the card from opponent hand
	$"../OpponentHand".remove_card_from_hand(card_with_highest_atk)
		# wait 1 second
	battle_timer.start()
	await battle_timer.timeout
	
func end_opponent_turn():
	$"../Deck".reset_draw()
	$"../CardManager".reset_player_monster()
	$"../EndTurnButton".disabled = false
	$"../EndTurnButton".visible = true
	
