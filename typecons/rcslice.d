
/** Parameters:
 * Length=uint saves register space but limits allocation size */
struct RCSlice(T, Length=uint)
{
private:
	Length offset;
	Length length;
	Impl* impl;

	struct Impl
	{
	private:
		/* Stored before *impl.
		 * Last byte determines preceding length size in bytes:
		 * nBytes = lengthBytes & 7 + 1 */
		ubyte[0] lengthBytes;
		uint refCount;
		Length capacity;
		T[0] data;
	}

	this(Length size)
	{
		const lbSize = 1 + 0;
		const n = lbSize + Impl.sizeof + T.sizeof * size;
		auto mem = new ubyte[n].ptr;
		impl = cast(Impl*)mem + lbSize;
		//static if (hasIndirections!T) GC.addRange
	}
}
