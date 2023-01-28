@safe:

///
@system assumeIsolated(T)(auto ref T v)
{
    auto r = Isolated!T(v);
    static if (__traits(compiles, v = null))
        v = null;
    return r;
}

///
struct Isolated(T)
if (__traits(compiles, (T v) { v = null; }))
{
    private T data;

    private this(T v) { data = v; }

    @disable this(this);

    ///
    auto move()
    {
        auto r = Isolated(data);
        data = null;
        return r;
    }

    ///
    T unwrap()
    {
        auto d = data;
        data = null;
        return d;
    }
}

interface IAllocator
{
    void* safeAllocate(size_t n);
    void safeDeallocate(Isolated!(void*) ip);
}

class Mallocator : IAllocator
{
    import core.stdc.stdlib : free, malloc;

    void* safeAllocate(size_t n) @trusted
    {
        return malloc(n);
    }

    void safeDeallocate(Isolated!(void*) ip) @trusted
    {
        ip.unwrap.free;
    }
}

void main()
{
    IAllocator a = new Mallocator;
    auto ip = (() @trusted => assumeIsolated(a.safeAllocate(4)))();
    a.safeDeallocate(ip.move);
    assert(ip.unwrap == null);
}
