extends "res://scenes/npc_dialogue.gd"

const DEFAULT_DIALOGUE := "I'm just chilling here. Feel free to rest, stranger!"
const RANDOM_DIALOGUES: Array[String] = [
	"The witch's voice... I covered my ears.",
	"The silver key — you'll need it to leave each floor.",
	"I've barely been eating recently...",
	"Bring Aldric back. He's the only one who can fix all of this. The rest of us... we're waiting",
	"Watch the floor. The witch grew spikes everywhere after Aldric vanished.",
	"Damn, I'm lowk kinda homeless. Wait, I am homeless!",
	"This dungeon used to be beautiful, I promise.",
	"Ms. Bookkeeper...",
]


func _ready() -> void:
	if dialogue_text.is_empty():
		dialogue_text = DEFAULT_DIALOGUE
	use_random_followups = true
	if random_followup_dialogues.is_empty():
		random_followup_dialogues = RANDOM_DIALOGUES.duplicate()
	super._ready()
