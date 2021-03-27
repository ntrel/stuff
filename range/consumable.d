module consumable;

public import optional;
import std.range;
import std.traits : isInstanceOf, lvalueOf;

enum isConsumable(T) = __traits(compiles,
	{static assert(isInstanceOf!(Optional, typeof(lvalueOf!T.next())));});

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
			return just(e);
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
			empty = opt.empty;
			if (!empty)
				e = opt.unwrap();
		}
	}
}
