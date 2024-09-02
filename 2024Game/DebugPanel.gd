extends PanelContainer

@onready var property_container = $MarginContainer/VBoxContainer
var property
var velocity_player : String
@onready var player = $"../../Player"
@onready var enemy = $"../../Zombie"

func _ready():
	_add_debug_proprty("test", "test")
	
func _process(delta):
	var velocity_player = player.velocity
		
	property.text = str(velocity_player)
func _add_debug_proprty(title : String,value):
	property = Label.new()
	property_container.add_child(property)
	property.name = title
	property.text = property.name + value
