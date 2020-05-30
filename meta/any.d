// 0.113s vs 0.133s for core.internal.traits
template anySatisfy(alias F, T...)
{
	static if (T.length == 0)
		enum anySatisfy = false;
	else static if (F!(T[0]))
		enum anySatisfy = true;
	else static if (T.length > 1)
	{
		static if (F!(T[1]))
			enum anySatisfy = true;
		else static if (T.length > 2)
		{
			static if (F!(T[2]))
				enum anySatisfy = true;
			else static if (T.length > 3)
			{
				static if (F!(T[3]))
					enum anySatisfy = true;
				else
				{
					static if (anySatisfy!(F, T[4..$][0..$/2]))
						enum anySatisfy = true;
					else
						enum anySatisfy = anySatisfy!(F, T[4..$][$/2..$]);
				}
			}
			else
				enum anySatisfy = false;
		}
		else
			enum anySatisfy = false;
	}
	else
		enum anySatisfy = false;
}

///
@safe unittest
{
    //~ import std.meta : anySatisfy;
    import std.traits : isIntegral;
    import std.meta : Repeat;

    static assert(!anySatisfy!(isIntegral, string, double));
    static assert( anySatisfy!(isIntegral, int, double));
    static foreach (i; 0..16)
	{{
		alias S = Repeat!(i, void);
		static assert(!anySatisfy!(isIntegral, S));
		static assert(anySatisfy!(isIntegral, S, int));
		static assert(anySatisfy!(isIntegral, S, int, S));
	}}
}

@safe unittest
{
    //~ import std.meta : anySatisfy;
    import std.meta : Repeat;
    import std.traits : isIntegral;

    enum n = 512;
    alias a = Repeat!(n, string);
    static assert(!anySatisfy!(isIntegral, a));
    static assert( anySatisfy!(isIntegral, a, int));
}


