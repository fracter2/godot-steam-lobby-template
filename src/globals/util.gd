class_name Util extends Object


## This is intended as a static-only helper class with convenience functions. [br]
## Functions are meant to be self-explanatory and independent.


static func limit_string_to_size(txt: String, size: int) -> String:
	assert(size > 0)
	if txt.length() > size:
		if size-3 > 0:
			txt = txt.substr(0, size-3) + '...'
		else:
			txt = txt.substr(0, size)
	return txt
