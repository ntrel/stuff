module consumable;

import std.range;
import std.traits;

enum isConsumable(T) = __traits(compiles,
	{static assert(typeof(lvalueOf!T.next()).isInstanceOf!Optional);});

template ElementType(C)
if (isConsumable!C)
{
	alias ElementType = typeof(lvalueOf!C.next.unwrap());
}

auto consumable(R)(R r)
if (!isConsumable!C)
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

auto cache(C)(C consumable)
if (isConsumable!C)
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
