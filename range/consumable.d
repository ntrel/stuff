import std.range;

private struct FilterResult(alias pred, Consumable)
{
	Consumable c;

	Optional!E next() {
		auto opt = c.next;
		if (!opt.isEmpty)
		{
			auto e = opt.unwrap;
			if (pred(e))
				return opt;
		}
		return Optional!E();
	}
}
private struct FilterResult(alias pred, Range)
{
	Range r;

	Optional!E next() {
		if (!r.empty)
		{
			auto e = r.front;
			r.popFront;
			if (pred(e))
				return optional(e);
		}
		return Optional!E();
	}
}

auto consumable(R)(R r)
{
	static struct Consumable
	{
		private R r;

		Optional!E next() {
			if (r.empty)
				return Optional!E();
			auto e = r.front;
			r.popFront;
			return optional(e);
		}
	}
	return Consumable(r);
}

import std.traits;
enum isConsumable(T) = is(typeof(lvalueOf!T.next()).isInstanceOf!Optional);

template ElementType(C)
if (isConsumable!C)
{
	alias ElementType = typeof(lvalueOf!C.next.unwrap());
}

auto cache(C)(C consumable)
{
	static struct Cache
	{
		private C c;
		private ElementType!C e;
		bool empty = true;

		this(C c)
		{
			this.c = c;
			popFront;
		}
		@property ref front()
		{
			assert(!empty);
			return e;
		}
		void popFront()
		{
			auto opt = c.next();
			empty = opt.isEmpty;
			if (!empty)
				e = opt.unwrap();
		}
	}
}
