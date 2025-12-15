extends State
@onready var disconnect_btn: Button = $"/root/Home/M/VBoxContainer/HBoxContainer/Disconnect"



func enter() -> void:
	disconnect_btn.disabled = true
	state_machine.copy_dnscrypt_to_userdir()
	state_machine.change_port()
	state_machine.set_default_dns()

func exit() -> void:
	disconnect_btn.disabled = false
