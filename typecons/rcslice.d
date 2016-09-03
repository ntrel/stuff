
/** Parameters:
 * Length=uint saves register space but limits allocation size */
@safe struct RCSlice(T, Length=uint)
{
private:
	T* data;
	Length offset;	// mem = data - offset
	Length length;

	struct Impl
	{
	private:
		uint refCount;
		T[0] data;
	}

	this(Length size) @trusted
	{
		const n = Impl.sizeof + T.sizeof * size;
		void[] mem = new ubyte[n];
		import core.memory, std.traits;
		static if (hasIndirections!T)
			GC.addRange(mem);

		auto impl = cast(Impl*)mem.ptr;
		impl.refCount = 1;
		data = impl.data.ptr;
	}
}

unittest
{
	RCSlice!int rcs;
}
