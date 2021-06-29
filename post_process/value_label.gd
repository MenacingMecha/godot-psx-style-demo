extends Label

func set_text_from_value(value: float, pad_zero_forward := true):
	set_text(("%02d" if pad_zero_forward else "%02.2f") % value)
