@safe:

@system assumeIsolated(T)(T v)
{
    return Isolated!T(v);
}

struct Isolated(T)
{
    private T data;
    
    private this(T v) { data = v; }
    
    @disable this(this);
    
    T unwrap()
    {
        auto d = data;
        data = null;
        return d;
    }
}

interface IAllocator
{
    void* allocate(size_t n);
    void safeDeallocate(ref Isolated!(void*) ip);
}

class Mallocator : IAllocator
{
    import core.stdc.stdlib : free, malloc;
    
    void* allocate(size_t n) @trusted
    {
        return malloc(n);
    }
    
    void safeDeallocate(ref Isolated!(void*) ip) @trusted
    {
        ip.unwrap.free;
    }
}

void main()
{
    IAllocator a = new Mallocator;
    auto ip = (() @trusted => assumeIsolated(a.allocate(4)))();
    a.safeDeallocate(ip);
    assert(ip.unwrap == null);
}
