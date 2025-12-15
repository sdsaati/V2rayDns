class_name StateMachine extends Node

@export var init_state: State
@onready var root: Control = $"/root/Home"
@onready var output: RichTextLabel = $"/root/Home/M/VBoxContainer/Output"
@onready var port: LineEdit = $"/root/Home/M/VBoxContainer/HBoxContainer2/Port"


@export var linux_name: String = r"v2ray_dns"
@export var windows_name: String = r"v2ray_dns.exe"
@export var config_name: String = r"v2ray_dns.toml"
@export var win_dns_default_script: String = r"win_def.bat"
@export var win_dns_local_script: String = r"win_loc.bat"
@export var linux_dns_default_script: String = r"linux_def.sh"
@export var linux_dns_local_script: String = r"linux_loc.sh"

var thread: Array
var thread_count: int
var stdout
var stdout_text: String
var output_thread: Thread
var running_proc: Dictionary
var current_state: State
var states: Dictionary[String, State] = {}


func _ready() -> void:
	thread = []
	thread_count = -1
	for child in get_children():
		if child is State:
			child.state_machine = self
			states[child.name.to_lower()] = child
	if init_state:
		current_state = init_state
		init_state.enter()


func change_state(new_state_name: String) -> void:
	var new_state: State = states.get(new_state_name.to_lower())
	assert(new_state, "State not found: " + new_state_name)
	if current_state:
		current_state.exit()
	current_state = new_state
	new_state.enter()

# ============================
# [HELPER METHODS]
# ============================
func _exit_tree():
	for t in thread:
		t.wait_to_finish()
		thread_count -= 1

func find_regex(pattern: String, in_this_str: String, capture_group_number: int = 0) -> String:
	var regex = RegEx.new()
	regex.compile(pattern)  # match one or more digits
	var result = regex.search(in_this_str)
	if result:
		return result.get_string(capture_group_number)
	return ""


func kill_process_by_name(process_name: String):
	match OS.get_name():
		"Windows":
			OS.execute("taskkill", ["/IM", process_name, "/F"], [], true)
		_:
			OS.execute("pkill", ["-f", process_name], [], true)


func get_dnscrypt() -> String:
	if OS.get_name() == "Windows":
		Global.echo("Your OS is an [color=#FFB64F]ugly [b]Windows[/b][/color]")
		return "user://" + windows_name
	elif OS.get_name() == "Linux":
		Global.echo("Your OS is a [color=#00FF00]beautiful lovely [b]Linux[/b][/color]")
		return "user://" + linux_name
	return "Not Supported"


func output_contains(output_text: String, keyword: String) -> bool:
	return output_text.to_lower().contains(keyword.to_lower())


func read_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		push_error("config file not found: " + path)
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open config file")
		return ""
	var content := file.get_as_text()
	file.close()
	return content


func write_config(content: String) -> void:
	var path := "user://" + config_name
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open " + config_name + "for writing")
		return
	file.store_string(content)
	file.close()



func change_port() -> void:
	var text := read_file("res://" + config_name)
	text = text.replace("127.0.0.1:10808", "127.0.0.1:" + port.text)
	write_config(text)


func read_config() -> String:
	return read_file("user://" + config_name)


func copy_dnscrypt_to_userdir() -> void:
	var sources: Array = []
	var dests: Array = []
	if OS.get_name() == "Windows":
		sources.append("res://" + win_dns_default_script)
		sources.append("res://" + win_dns_local_script)
	elif OS.get_name() == "Linux":
		sources.append("res://" + linux_dns_default_script)
		sources.append("res://" + linux_dns_local_script)

	if OS.get_name() == "Windows":
		dests.append("user://" + win_dns_default_script)
		dests.append("user://" + win_dns_local_script)
	elif OS.get_name() == "Linux":
		dests.append("user://" + linux_dns_default_script)
		dests.append("user://" + linux_dns_local_script)
	
	var counter: int = 0
	for f in sources:
		if not FileAccess.file_exists(dests[counter]):
			DirAccess.copy_absolute(f, dests[counter])
		if OS.get_name() == "Linux":
			OS.execute("chmod", ["+x", ProjectSettings.globalize_path(dests[counter])])
		counter += 1

	var src := ""
	if OS.get_name() == "Windows":
		src = "res://" + windows_name
	elif OS.get_name() == "Linux":
		src = "res://" + linux_name

	var dst := "user://" + windows_name if OS.get_name() == "Windows" else "user://" + linux_name
	if not FileAccess.file_exists(dst):
		DirAccess.copy_absolute(src, dst)
	if OS.get_name() == "Linux":
		OS.execute("chmod", ["+x", ProjectSettings.globalize_path(dst)])


func run_program() -> void:
	var exe := get_dnscrypt()
	stdout = []
	running_proc = OS.execute_with_pipe(ProjectSettings.globalize_path(exe), ["-config", ProjectSettings.globalize_path("user://" + config_name)], false)
	if running_proc.is_empty():
		print("Failed")
		return
	# Start a thread to read stdout/stderr
	output_thread = Thread.new()
	output_thread.start(Global.handle_v2dns_outputs.bind(running_proc))
	
	
func set_default_dns():
	# set the dns to 8.8.8.8 and 1.1.1.1
	var script: String = ""
	if OS.get_name() == "Windows":
		script = win_dns_default_script
	elif OS.get_name() == "Linux":
		script = linux_dns_default_script
	var out := []
	var exit_code := OS.execute(
		ProjectSettings.globalize_path("user://" + script),
		[], # arguments
		out,
		true
	)
	var text_output := "\n".join(out)
	Global.echo("[b][color=#ffaa00]Setting global DNS servers to [color=#cc7700]normal[/color] google and cloudflare:[/color][/b]")
	Global.echo(text_output.trim_suffix("\n"))
	#print(text_output)
	#print("Exit code:", exit_code)
	return text_output


func set_v2ray_dns():
	# set the dns to 127.0.0.1
	var script: String = ""
	if OS.get_name() == "Windows":
		script = win_dns_local_script
	elif OS.get_name() == "Linux":
		script = linux_dns_local_script
	var out := []
	var exit_code := OS.execute(
		ProjectSettings.globalize_path("user://" + script),
		[], # arguments
		out,
		true
	)
	var text_output := "\n".join(out)
	Global.echo("[b][color=#ffaa00]Setting global DNS servers to [color=#cc7700]encrypted and proxified[/color] DNS server:[/color][/b]")
	Global.echo(text_output.trim_suffix("\n"))
	#print(text_output)
	#print("Exit code:", exit_code)
	return text_output


func _notification(what):
	# this function will be run when we close the application
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		change_state("Disconnected")
		get_tree().quit() # allow the app to quit


# ============================
# [EVENTS]
# ============================
func _on_connect_pressed() -> void:
	change_state("Connected")


func _on_disconnect_pressed() -> void:
	change_state("Disconnected")
