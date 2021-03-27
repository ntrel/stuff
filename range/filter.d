import consumable;

private struct FilterResult(alias pred, Consumable)
if (isConsumable!Consumable)
{
	Consumable c;

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

	Optional!E next() {
		while (!r.empty)
		{
			auto e = r.front;
			r.popFront;
			if (pred(e))
				return optional(e);
		}
		return Optional!E();
	}
}

unittest
{
	auto c = FilterResult!(e => e & 1, int[])([1,2,3,4,5]);
	while(1)
	{
		auto opt = c.next;
		if (opt.isEmpty)
			break;
		opt.unwrap.writeln;
	}
}
