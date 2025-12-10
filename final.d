/// Type constructor
struct Final(T)
{
    private T v;
    
    this(T v) { this.v = v; }
    
    alias this = get;
    /// convert to rvalue
    T get() => v;
    
    /// avoid copying a value type
    const ref getRef() => v;
    
    bool opEquals(T v) => this.v == v;

    @disable void opAssign(U)(U u);

    // TODO other ops, constraints
    ref opUnary(string op : "*")() => *v;
    @disable void opUnary(string op)();

    ref opIndex()(size_t i) if (__traits(compiles, v[i])) => v[i];

    /// Returns: rvalue
    // Return Final ref?
    auto opDispatch(string f)() => mixin("v." ~ f);
}
auto final_(T)(T v) => Final!T(v);

/// int
unittest
{
    Final!int f = 1;
    assert(f == 1);
    int i = f;
    assert(i == 1);
}

/// pointer
unittest
{
    int i;
    auto f = final_(&i);
    assert(f == &i);
    static assert(!__traits(compiles, f = &i));
    static assert(!__traits(compiles, f = final_(&i)));
    static assert(!__traits(compiles, f++));

    (*f)++;
    assert(i == 1);
}

/// array
unittest
{
    int[] a = [1];
    auto f = final_(a);
    static assert(!__traits(compiles, f.length++));
    assert(f.length == 1);
    assert(f[0] == 1);

    (*f.ptr)++;
    assert(f == [2]);
    f.ptr[0] = 3;
    assert(f == [3]);

    a = [1];
    assert(a !is f.get);
    a = f;
    assert(a is f.get);
}
