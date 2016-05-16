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
private:
	struct Impl
	{
		immutable size_t size;
		T[] unused;
		T[0] _data;
		
		@property data() @trusted
		{
			return _data.ptr[0..size];
		}
	}
	Impl* impl;
	
	this(size_t size) @system
	{
		// TODO: don't initialize data
		// TODO: round up allocation
		auto bytes = new ubyte[Impl.sizeof + size].ptr;
		*cast(size_t*)bytes = size;
		impl = cast(Impl*)bytes;
		with (impl) unused = _data;
	}
	
public:
	~this()
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
	
	// uses chunk.impl.unused
	void opAppend(Slice s);

	~this()
	{
		//data.ptr = null; // may be base
		data = [];
	}
}

///
Slice!T slice(T, n)(T[n] items...) @trusted
{
	auto c = Chunk!T(n);
	auto s = Slice!T(c, c.data[0..n]);
	s.data[] = items;
	c.impl.unused = c.data[n..$];
	return s;
}

///
unittest
{
	auto s = slice(3, 2, 1);
	assert(s.data == [3, 2, 1]);
}

