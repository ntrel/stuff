import std.meta : AliasSeq, Repeat;

template staticIota(size_t n)
{
	auto gen()
	{
		alias E = size_t;
		// make string for type sequence
		auto ts()
		{
			char[n * 2 - 1] s = 'E';
			foreach (i; 1..n)
				s[i * 2 - 1] = ',';
			return s;
		}
		// wrap a type sequence instance so we can return it
		struct S
		{
			//~ AliasSeq!(Repeat!(n, E)) vals;
			mixin("AliasSeq!(", ts(), ") vals;");
		}
		S s;
		static foreach (i; 0..n)
			s.vals[i] = i;
		return s;
	}
    enum staticIota = gen().vals;
}

//~ import std.range : iota;
//~ import std.meta : aliasSeqOf;
//~ pragma(msg, aliasSeqOf!(iota(64)));
//~ pragma(msg, staticIota!64);

