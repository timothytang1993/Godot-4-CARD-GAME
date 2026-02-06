extends Node2D

const CARD_SCENE_PATH = "res://Scenes/Card.tscn"
const CARD_DRAW_SPEED = 0.2
const STARTING_HAND_SIZE = 5

var player_deck = ["Knight", "Archer", "Demon", "Knight", "Knight", "Knight", "Knight", "Knight"]
var card_database_reference: Script
var drag_card_this_turn = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_deck.shuffle()
	$RichTextLabel.text = str(player_deck.size())
	card_database_reference = preload("res://Scripts/CardDatabase.gd")
	for i in range(STARTING_HAND_SIZE):
		draw_card()
		drag_card_this_turn = false
	drag_card_this_turn = true
	
func draw_card():
	if drag_card_this_turn:
		return
		
	drag_card_this_turn = true
	var card_drawn_mame = player_deck[0]
	player_deck.erase(card_drawn_mame)
	
	# if the player draw the last card at deck
	if player_deck.size() == 0:
		$Area2D/CollisionShape2D.disabled = true
		$Sprite2D.visible = false
		$RichTextLabel.visible = false
		
	$RichTextLabel.text = str(player_deck.size())
	var card_scene = preload(CARD_SCENE_PATH)
	#for i in range(player_deck.size()):
	var new_card = card_scene.instantiate()
	var card_image_path = str("res://Assets/") + card_drawn_mame + ("Card.png")
	new_card.get_node("CardImage").texture = load(card_image_path)
	new_card.get_node("Attack").text = str(card_database_reference.CARDS[card_drawn_mame][0])
	new_card.get_node("Health").text = str(card_database_reference.CARDS[card_drawn_mame][1])
	new_card.card_type = str(card_database_reference.CARDS[card_drawn_mame][2])
	$"../CardManager".add_child(new_card)
	new_card.name = "Card"
	$"../PlayerHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
	new_card.get_node("AnimationPlayer").play("card_flip")

func reset_draw():
	drag_card_this_turn = false
