extends Node

const SMALL_CARD_SCALE = 0.3
const CARD_MOVE_SPEED = 0.2
const STARTING_HEALTH = 10
const BATTLE_POS_OFFSET = 25

var battle_timer
var empty_monster_card_slots = []
var opponent_card_on_battlefield = []
var player_card_on_battlefield = []
var player_cards_that_attack_this_turn = []
var player_health
var opponent_health
var is_opponent_turn = false
var player_is_attacking = false

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
	
	player_health = STARTING_HEALTH
	$"../PlayerHealth".text =str(player_health)
	opponent_health = STARTING_HEALTH
	$"../OpponentHealth".text =str(opponent_health)

func _on_end_turn_button_pressed() -> void:
	is_opponent_turn = true
	$"../CardManager".unselect_select_monster()
	player_cards_that_attack_this_turn = []
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
	
	# Check if any free slot, play monster with with highest attack if so
	if empty_monster_card_slots.size() != 0:
		await try_play_card_with_highest_attack()
		
	# try attack
	# check if at least 1 card on opponent battlefield
	if opponent_card_on_battlefield.size() != 0:
		# Create a new array with all the opponent cards to loop through
		var enermy_card_to_attack = opponent_card_on_battlefield.duplicate()
		# Each opponent attack
		for card in enermy_card_to_attack:
			# if at least one card on playerfield
			if player_card_on_battlefield.size() != 0:
				var card_to_attack = player_card_on_battlefield.pick_random()
				await attack(card, card_to_attack, "opponent")
			else:
				await direct_attack(card, "Opponent")
			# perform direct attack
			
	end_opponent_turn()

func direct_attack(attacking_card, attacker):
	var new_pos_y
	if attacker == "Opponent":
		new_pos_y = 1080
	else:
		$"../EndTurnButton".disabled = true
		$"../EndTurnButton".visible = false
		player_is_attacking = true
		new_pos_y = 0
		player_cards_that_attack_this_turn.append(attacking_card)
	var new_pos = Vector2(attacking_card.position.x, new_pos_y)
	
	attacking_card.z_index = 5
	
	# Animate card to position
	var tween = get_tree().create_tween()
	tween.tween_property(attacking_card, "position", new_pos, CARD_MOVE_SPEED)
	await wait(0.15)
	
	if attacker == "Opponent":
		player_health = max(0, player_health - attacking_card.attack)
		$"../PlayerHealth".text =str(player_health)
	else:
		opponent_health =  max(0, opponent_health - attacking_card.attack)
		$"../OpponentHealth".text =str(opponent_health)
		
	var tween2 = get_tree().create_tween()
	tween2.tween_property(attacking_card, "position", attacking_card.card_slot_card_is_in.position, CARD_MOVE_SPEED)
	attacking_card.z_index = 0
	await wait(1)
	if attacker == "Player":
		player_is_attacking = false
		$"../EndTurnButton".disabled = false
		$"../EndTurnButton".visible = true
	
func attack(attacking_card, defending_card, attacker):
	if attacker == "Player":
		player_is_attacking = true
		$"../EndTurnButton".disabled = true
		$"../EndTurnButton".visible = false
		$"../CardManager".selected_monster = null
		player_cards_that_attack_this_turn.append(attacking_card)
		
	attacking_card.z_index = 5
	var new_pos = Vector2(defending_card.position.x, defending_card.position.y + BATTLE_POS_OFFSET)
	var tween = get_tree().create_tween()
	tween.tween_property(attacking_card, "position", new_pos, CARD_MOVE_SPEED)
	await wait(0.15)
	
	var tween2 = get_tree().create_tween()
	tween2.tween_property(attacking_card, "position", attacking_card.card_slot_card_is_in.position, CARD_MOVE_SPEED)
	
	# Card damage
	defending_card.health = max(0, defending_card.health - attacking_card.attack)
	defending_card.get_node("Health").text = str(defending_card.health)
	attacking_card.health = max(0, attacking_card.health - defending_card.attack)
	attacking_card.get_node("Health").text = str(attacking_card.health)
	
	await wait(1.0)
	attacking_card.z_index = 0
	
	var card_was_distoryed = false
	# Distory card if card health is 0
	if attacking_card.health == 0:
		destory_card(attacking_card, attacker)
		card_was_distoryed = true
	if defending_card.health == 0:
		if attacker == "Player":
			destory_card(defending_card, "Opponent")
		else:
			destory_card(defending_card, "Player")
		card_was_distoryed = true
		
	if card_was_distoryed:
		await wait(1.0)
	
	if attacker == "Player":
		player_is_attacking = false
		$"../EndTurnButton".disabled = false
		$"../EndTurnButton".visible = true
		
func destory_card(card, card_owner):
	var new_pos
	if card_owner == "Player":
		card.defeated = true
		card.get_node("Area2D/CollisionShape2D").disabled = true
		new_pos = $"../PlayerDiscard".position
		if card in player_card_on_battlefield:
			player_card_on_battlefield.erase(card)
		card.card_slot_card_is_in.get_node("Area2D/CollisionShape2D").disabled = false
	else:
		new_pos = $"../OpponentDiscard".position
		if card in opponent_card_on_battlefield:
			opponent_card_on_battlefield.erase(card)
			
	card.card_slot_card_is_in.card_in_slot =false
	card.card_slot_card_is_in = null
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_pos, CARD_MOVE_SPEED)

func enemy_card_selected(defending_card):
	var attacking_card = $"../CardManager".selected_monster
	if attacking_card:
		if defending_card in opponent_card_on_battlefield:
			if player_is_attacking == false:
				$"../CardManager".selected_monster = null
				attack(attacking_card, defending_card, "Player")
	
func try_play_card_with_highest_attack():
	# Check if any card is in hand
	var opponent_hand = $"../OpponentHand".opponent_hand
	if opponent_hand.size() == 0:
		end_opponent_turn()
		return
	
	# Get random empty slot to play the card in
	var random_empty_monster_card_slot = empty_monster_card_slots.pick_random()
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
	card_with_highest_atk.card_slot_card_is_in = random_empty_monster_card_slot
	opponent_card_on_battlefield.append(card_with_highest_atk)
	
	# wait 1 second
	await wait(1.0)
	
func wait(wait_time):
	battle_timer.wait_time =wait_time
	battle_timer.start()
	await battle_timer.timeout


func end_opponent_turn():
	$"../Deck".reset_draw()
	$"../CardManager".reset_player_monster()
	is_opponent_turn = false
	$"../EndTurnButton".disabled = false
	$"../EndTurnButton".visible = true
	
