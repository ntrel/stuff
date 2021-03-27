import consumable;
import std.range;

private struct FilterResult(alias pred, Consumable)
if (isConsumable!Consumable)
{
	Consumable c;
	alias E = ElementType!Consumable;

	Optional!E next() {
		auto opt = c.next;
		while (!opt.isEmpty)
		{
			auto e = opt.unwrap;
			if (pred(e))
				return opt;
		}
		return Optional!E();
	}
}
private struct FilterResult(alias pred, Range)
if (!isConsumable!Range)
{
	Range r;
	alias E = ElementType!Range;

	Optional!E next() {
		while (!r.empty)
		{
			auto e = r.front;
			r.popFront;
			if (pred(e))
				return just(e);
		}
		return Optional!E();
	}
}
auto filter(alias pred, R)(R r) {
	return FilterResult!(pred, R)(r);
}

unittest
{
	import std.stdio;

	auto c = filter!(e => e & 1)([1,2,3,4,5]);
	while(1)
	{
		auto opt = c.next;
		if (opt.empty)
			break;
		opt.unwrap.writeln;
	}
}
