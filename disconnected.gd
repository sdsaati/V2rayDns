extends State
@onready var disconnect_btn: Button = $"/root/Home/M/VBoxContainer/HBoxContainer/Disconnect"

func enter() -> void:
	disconnect_btn.disabled = true
	if OS.get_name() == "Windows":
		state_machine.kill_process_by_name(state_machine.windows_name)
		state_machine.kill_process_by_name("dnscrypt-proxy.exe")
	elif OS.get_name() == "Linux":
		state_machine.kill_process_by_name(state_machine.linux_name)
		state_machine.kill_process_by_name("dnscrypt-proxy")
	state_machine.set_default_dns()

func exit() -> void:
	disconnect_btn.disabled = false
