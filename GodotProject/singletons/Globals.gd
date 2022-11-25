extends Node

var jeux = {}

var jeu_a_charger = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	var file = File.new()
	file.open("res://niveaux/jeux.tres", File.READ)
	var content = file.get_as_text().strip_edges()
	file.close()
	jeux = JSON.parse(content).result

func compress(message):
	var encoded_string = ""
	var i = 0
	while (i <= len(message)-1):
		var count = 1
		var ch = message[i]
		var j = i
		while (j < len(message)-1): 
			if (message[j] == message[j + 1]): 
				count = count + 1
				j = j + 1
			else: 
				break
		var b = str(count) if count > 1 else ""
		encoded_string = encoded_string + b + ch
		i = j + 1
	return encoded_string
