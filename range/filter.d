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

