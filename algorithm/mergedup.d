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

import std.stdio;
unittest
{
	merge([1,3,4,6],[2,3,5]).writeln;
}

// TODO: share result array
/// Unique merge sort
auto mergeSort(T)(T[] a)
{
	if (a.length < 2)
		return a;
	import std.algorithm : swap;
	if (a.length == 2)
	{
		auto cmp = a[1] - a[0];
		return (cmp > 0) ? a :
			(cmp < 0) ? [a[1], a[0]] : a[0..1];
	}
	return merge(mergeSort(a[0..$/2]), mergeSort(a[$/2..$]));
}

unittest
{
	mergeSort([4,2,5,1,3,4,2,2]).writeln;
}
