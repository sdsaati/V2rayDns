extends Node
@onready var output = $"/root/Home/M/VBoxContainer/Output"
@onready var state_machine: StateMachine = $"/root/Home/StateMachine"
var v2dns_output: String

func echo(text: String) -> void:
	output.text += text + "\n"


func handle_v2dns_outputs(proc_info):
	var pipe: FileAccess
	var err: FileAccess
	#print("we are handling v2dns output for pid: " + str(proc_info["pid"]))
	# Read until EOF
	while OS.is_process_running(proc_info["pid"]):
		pipe = proc_info.get("stdio", null) as FileAccess
		err = proc_info.get("stderr", null) as FileAccess
		if pipe:
			var line = pipe.get_line()
			if pipe.get_error() == OK:
				call_deferred("on_v2dns_output", line)
		if err:
			var line = err.get_line()
			if err.get_error() == OK:
				call_deferred("on_v2dns_output", line)
		OS.delay_msec(10)
	return null


func on_v2dns_output(line: String) -> void:
	if state_machine.output_contains(line, "FATAL") or state_machine.output_contains(line, "ERROR"):
		Global.echo('[color=#FF5555][b]Error:[/b] couldn\'t connect to dns service.[/color]')
		Global.echo(line)
		state_machine.change_state("Disconnected")
	elif state_machine.output_contains(line, "OK (DoH) - rtt:"):
		Global.echo('[color=#55ff55][b]Successfully[/b][/color] works.')
		var server_name = state_machine.find_regex(r"\[(\w+)\]\sOK\s.*?rtt:\s(\d+)ms", line, 1)
		var server_ping = state_machine.find_regex(r"\[(\w+)\]\sOK\s.*?rtt:\s(\d+)ms", line, 2)
		Global.echo("You connected to [b][color=#8b4aab]" + server_name.capitalize() + "[/color][/b] DNS server [color=#55ff55]successfully[/color].")
		Global.echo("Your ping time to the DNS server is : [b][color=#5555ff]" + server_ping + "[/color][/b] ms")
		state_machine.set_v2ray_dns()
	#Global.v2dns_output += line + "\n"
	#print(line)
