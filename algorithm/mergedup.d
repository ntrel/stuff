// merge, ignoring corresponding duplicates (but not inline duplicates)
T[] merge(T)(T[] a, T[] b, T[] result = [])
if (__traits(compiles, b[0] - a[0]))
{
	debug import std.stdio;
	size_t i, j;
	while (i != a.length && j != b.length)
	{
		debug writeln(result, a[i..$], ' ', b[j..$]);
		auto cmp = b[j] - a[i];
		static if (0)
		{
			if (cmp <= 0)
				result ~= b[j++];
			if (!cmp)
				i++; // ignore duplicate
			else if (cmp > 0)
				result ~= a[i++];
		}
		else 
		{	// avoid branch stalls
			T[2] r = [b[j], a[i]];
			result ~= r[cmp > 0];
			j += cmp <= 0;
			i += cmp >= 0;
		}
	}
	debug writeln(result, a[i..$], ' ', b[j..$]);
	foreach (e; a[i..$])
		result ~= e;
	foreach (e; b[j..$])
		result ~= e;
	return result;
}

unittest
{
	import std.stdio;
	merge([1,3,4,6],[2,3,5]).writeln;
}
