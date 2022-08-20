template zeroInit(T)
{
	union U
	{
		byte[T.sizeof] a;
		T zeroed;
	}
	enum zeroInit = U().zeroed;
}

struct S
{
	float f;
	struct
	{
		float[2] a;
	}
}

void main()
{
	S s = zeroInit!S;
	assert(s.f == 0);
	assert(s.a == [0,0]);
}
