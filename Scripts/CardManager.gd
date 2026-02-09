extends Node2D

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_CARD_SLOT = 2
const DEFAULT_CARD_MOVE_SPEED = 1
const DEFAULT_CARD_SCALE = 0.4
const CARD_BIGGER_SCALE = 0.45
const CARD_SMALL_SCALE = 0.3

var screen_size
var card_being_dragged
var is_hovering_on_card: bool = false
var player_hand_reference
var player_monster_card_this_turn = false
var selected_monster
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport().size
	player_hand_reference = card_being_dragged
	player_hand_reference = $"../PlayerHand"
	$"../InputManager".connect("left_mouse_button_released", on_left_click_released)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if card_being_dragged:
		var mouse_pos = get_global_mouse_position()
		card_being_dragged.position = Vector2(clamp(mouse_pos.x, 0, screen_size.x),
			clamp(mouse_pos.y, 0, screen_size.y))
	
#func _input(event: InputEvent) -> void:
	#if event is InputEventMouseButton and event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
		#if event.pressed:
			#var card = raycast_check_for_card()
			#if card:
				#start_drag(card)
		#else:
			#if card_being_dragged:
				#finish_drag()
func card_clicked(card):
	# Card if card on battlefield or in hand
	if card.card_slot_card_is_in:
		if $"../BattleManager".is_opponent_turn == false:
			if $"../BattleManager".player_is_attacking == false:
				# Card on battlefield
				if card not in $"../BattleManager".player_cards_that_attack_this_turn:
					if $"../BattleManager".opponent_card_on_battlefield.size() == 0:
						$"../BattleManager".direct_attack(card, "Player")
						return
				else:
					select_card_for_battle(card)
	else:
		start_drag(card)

func select_card_for_battle(card):
	# Toggle selected card
	if selected_monster:
		# if card ready selected
		if selected_monster == card:
			card.position.y += 20
			selected_monster = null
		else:
			selected_monster.position += 20
			selected_monster = card
			card.position.y -= 20
	else:		
		selected_monster = card
		card.position.y -= 20
	
	
func start_drag(card):
	card_being_dragged = card
	card.scale = Vector2(DEFAULT_CARD_SCALE, DEFAULT_CARD_SCALE)
	
func finish_drag():
	card_being_dragged.scale = Vector2(CARD_BIGGER_SCALE, CARD_BIGGER_SCALE)
	var card_slot_found = raycast_check_for_card_slot()
	if card_slot_found and not card_slot_found.card_in_slot:
		# if the card can be placed in this slot
		if card_being_dragged.card_type == card_slot_found.card_slot_type:
			if !player_monster_card_this_turn:
				# Card dropped in empty card slot
				card_being_dragged.scale = Vector2(CARD_SMALL_SCALE, CARD_SMALL_SCALE)
				card_being_dragged.z_index = -1
				is_hovering_on_card = false
				card_being_dragged.card_slot_card_is_in = card_slot_found
				player_hand_reference.remove_card_from_hand(card_being_dragged)
				card_being_dragged.position = card_slot_found.position
				#card_being_dragged.get_node("Area2D/CollisionShape2D").disabled = true
				card_slot_found.card_in_slot = true
				card_slot_found.get_node("Area2D/CollisionShape2D").disabled = true
				$"../BattleManager".player_card_on_battlefield.append(card_being_dragged)
				card_being_dragged = null
				return
	player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEED)
	card_being_dragged = null
		#else:
			#player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEED)
	#else:

func unselect_select_monster():
	if selected_monster:
		selected_monster.position.y += 20
		selected_monster = null
		
	
func connect_card_signals(card):
	card.connect("hovered", on_hovered_over_card)
	card.connect("hovered_off", on_hovered_off_card)

func on_left_click_released():
	if card_being_dragged:
		finish_drag()

func on_hovered_over_card(card):
	if card.card_slot_card_is_in:
		return
	if !is_hovering_on_card:
		is_hovering_on_card = true
		highest_card(card, true)
	
func on_hovered_off_card(card):
	if card.defeated:
		# Check if card is not in card slot and being dragged
		if !card.card_slot_card_is_in && !card_being_dragged:
			highest_card(card, false)
			# Check if hovered off card straight on to another card
			var new_card_hovered = raycast_check_for_card()
			if new_card_hovered:
				highest_card(new_card_hovered, true)
			else:
				is_hovering_on_card = false
		
func highest_card(card, hovered):
	if hovered:
		card.scale = Vector2(CARD_BIGGER_SCALE, CARD_BIGGER_SCALE)
		card.z_index = 2
	else:
		card.scale = Vector2(DEFAULT_CARD_SCALE, DEFAULT_CARD_SCALE)
		card.z_index = 2

func raycast_check_for_card_slot():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD_SLOT
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return result[0].collider.get_parent()
	return null
	
func raycast_check_for_card():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		#return result[0].collider.get_parent()
		return get_card_with_highest_z_index(result)
	return null

func get_card_with_highest_z_index(cards):
	# Assume the first card to cards array has the highest z index
	var highest_z_card = cards[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index
	
	# loop through the rest of the cards checking for a higher z index
	for i in range(1, cards.size()):
		var current_card = cards[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	
	return highest_z_card

func reset_player_monster():
	player_monster_card_this_turn = false
