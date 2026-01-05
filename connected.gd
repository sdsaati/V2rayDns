extends State
@onready var connect_btn: Button = $"/root/Home/M/VBoxContainer/HBoxContainer/Connect"


func enter() -> void:
	connect_btn.disabled = true
	state_machine.change_port()
	state_machine.run_program()
	Global.echo("[color=#ff0000]..................... Please Wait .....................[/color]")




func exit() -> void:
	connect_btn.disabled = false
