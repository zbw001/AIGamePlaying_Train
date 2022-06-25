extends Node

func convert_len(fr_len, fr, to):
	assert(fr_len >= 0)
	var p1 = to.to_local(fr.to_global(Vector2(0, fr_len)))
	var p2 = to.to_local(fr.to_global(Vector2(0, 0)))
	var ret = (p1 - p2).y
	assert(ret > 0)
	return ret
