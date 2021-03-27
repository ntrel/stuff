// not C:\Users\user\AppData\Local\dub\packages\optional-1.2.0\optional\source
module optional;

struct Optional(T)
{
	private T data;
	bool empty = true;

	this(T v) {
		data = v;
		empty = false;
	}

	T unwrap() {
		assert(!empty);
		return data;
	}
}

// can't call this `optional` :-/
auto just(T)(T v)
{
	return Optional!T(v);
}
