/** WIP: A RC array that prevents stomping of immutable sliced data */

/** Parameters:
 * Length=uint saves register space but limits allocation size */
@safe struct RCSlice(T, Length=uint)
{
private:
	T* data;
	Length offset;	// impl.data = data - offset
	Length length;

	struct Impl
	{
	private:
		uint refCount;
		Length size;
		Length used;	// prevents stomping
		T[0] data;
	}

	static @property allocSize(Length l){return Impl.sizeof + T.sizeof * l;}

	this(Length size) @trusted
	{
		void[] mem = new ubyte[allocSize(size)];
		import core.memory, std.traits;
		static if (hasIndirections!T)
			GC.addRange(mem.ptr, mem.length);

		auto impl = cast(Impl*)mem.ptr;
		impl.refCount = 1;
		impl.size = size;
		data = impl.data.ptr;
	}

	~this() @trusted
	{
		auto mem = cast(ubyte*)(data - offset) - Impl.sizeof;
		import core.memory, std.traits;
		static if (hasIndirections!T)
			GC.removeRange(mem);
	}
}

unittest
{
	RCSlice!int rcs;
	RCSlice!Object rcs2;
}
