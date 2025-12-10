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

    // We can define mutable ref access only when result is not part of T's storage
    // Note: A struct could define an op to refer to part of itself
    // Note: A struct could convert to pointer/slice but still overload the op
    ref opUnary(string op : "*")() if (is(T == U*, U)) => *v;

    ref opIndex()(size_t i) if (is(T == U[], U)) => v[i];

    /// Returns: rvalue
    // Return Final ref?
    auto opDispatch(string f)()
    if (__traits(compiles, __traits(getMember, v, f))) => mixin("v." ~ f);

    // TODO other ops?
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
    assert(*f == 1);
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
