/* Written in the D programming language.
 * Copyright: 2016 Nick Treleaven <nick dot treleaven at btinternet com>
 * License: Boost Software License, Version 1.0. See accompanying file
 *          LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt.
*/

/** Safe slicing compatible with a GC that doesn't detect internal pointers.
 * Pointers should get nulled when no longer used, unless they are not
 * base pointers, to prevent leaks.
 */
module slice;

@safe:

/** Chunk may allow for more reuse of unused space than T[].
 */
struct Chunk(T)
{
@system:
private:
	struct Impl
	{
		immutable size_t size;
		T[] unused;
		T[0] _data;
		
		@property data()
		{
			return _data.ptr[0..size];
		}
	}
	Impl* impl;
	
public:
	this(size_t size)
	{
		// TODO: don't initialize data
		// TODO: round up allocation
		auto bytes = new void[Impl.sizeof + size].ptr;
		*cast(size_t*)bytes = size;
		impl = cast(Impl*)bytes;
		with (impl) unused = data;
	}
	
	auto take(size_t n)
	{
		import std.range;
		with (impl)
		{
			unused.drop(n);
			return data[0..n];
		}
	}
	
	~this() @safe
	{
		// clear base memory reference
		impl = null;
	}
}


///
struct Slice(T)
{
private:
	Chunk!T chunk;
	T[] data;
	
public:
	ref opIndex(size_t index)
	{
		return data[index];
	}
	
	@property length()
	{
		return data.length;
	}
	
	Slice opSlice(size_t, size_t);
	
	// uses chunk.impl.unused
	void opAppend(Slice s);

	~this()
	{
		// clear possible base pointer
		//data.ptr = null;
		data = [];
	}
}

///
Slice!T slice(T, size_t n)(T[n] items...) @trusted
{
	auto c = Chunk!T(n);
	auto s = Slice!T(c, c.take(n));
	s.data[] = items;
	return s;
}

///
unittest
{
	auto s = slice(3, 2, 1);
	assert(s.data == [3, 2, 1]);
}

