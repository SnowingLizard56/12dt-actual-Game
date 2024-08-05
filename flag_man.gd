class_name FlagManager extends Object

static var flags:Array[bool] = []
static var callable_holder:Array[Array] = []


static func set_flag(index:int, value:bool):
	update_length(index)
	flags[index] = value
	for i in FlagManager.callable_holder[index]:
		if i[1] != value: continue
		i[0].call()


static func on_flag(index:int, callable:Callable, invert:bool=false):
	update_length(index)
	FlagManager.callable_holder[index].append([callable, invert])


static func clear_flags():
	FlagManager.flags = []
	FlagManager.callable_holder = []


static func update_length(min_index:int):
	if min_index < len(flags): return
	for i in min_index - len(flags) + 1:
		flags.append(false)
		callable_holder.append([])
