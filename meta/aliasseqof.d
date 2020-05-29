import std.traits : isIterable;
import std.range.primitives, std.meta : AliasSeq, Repeat;

template aliasSeqOf(alias iter)
// TODO: ts() requires iter.length, but this could be gotten from iter.array when necessary, reusing it later
if (isIterable!(typeof(iter)) && hasLength!(typeof(iter)))
{
	auto gen()
	{
		alias E = ElementType!(typeof(iter));
		enum n = iter.length; // workaround for bug with Repeat when iter = iota(N)
		//~ pragma(msg, Repeat!(n, E)); // about the same speed, but CTFE may get faster
		auto ts()
		{
			char[n * 2 - 1] str = 'E';
			foreach (i; 1..n)
				str[i * 2 - 1] = ',';
			return str;
		}
		//~ pragma(msg, ts());
		// wrap type sequence instance
		struct S
		{
			//~ AliasSeq!(Repeat!(n, E)) rvals;
			AliasSeq!(mixin("AliasSeq!(", ts(), ')')) rvals;
		}
		S s;
		static if (isRandomAccessRange!(typeof(iter)))
		{
			static foreach (i; 0..iter.length)
			{
				s.rvals[i] = iter[i];
			}
		}
		else static if (isInputRange!(typeof(iter)))
		{
			static foreach (i; 0..iter.length)
			{
				s.rvals[i] = r.front;
				r.popFront;
			}
		}
		else
		{
			//~ import enumerate;
			//~ static foreach (i, e; Enumerate!(iter))
				//~ s.rvals[i] = e;
			import std.range : array;
			auto a = iter.array;
			static foreach (i, e; iter)
				s.rvals[i] = e;
		}
		return s;
	}
    enum aliasSeqOf = gen().rvals;
}

private template staticIota(size_t N)
{
	import std.range : iota;
	//~ import std.meta : aliasSeqOf;
	alias staticIota = aliasSeqOf!(iota(N));
}
pragma(msg, staticIota!64);
