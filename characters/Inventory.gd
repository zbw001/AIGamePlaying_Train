extends Node

# 不如自己写一个。。。

var item_cnt = {}

var item_selected = null

func reset():
	item_cnt = {}
	item_selected = null

func count_item(item_id: String) :
	if not (item_id in item_cnt) :
		return 0
	return item_cnt[item_id]


func add_item(item_id : String, cnt : int):
	if not (item_id in item_cnt):
		item_cnt[item_id] = 0
	item_cnt[item_id] = min(item_cnt[item_id] + cnt, Consts.MAX_ITEM_CNT)

func remove_item(item_id, cnt):
	assert(item_id in item_cnt and cnt <= item_cnt[item_id])
	item_cnt[item_id] -= cnt
