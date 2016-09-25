/* Set initially written by Andrej Mitrovic */

///
struct Set(T)
{
    private void[0][T] set;  // void[0] does not allocate
    
    ///
    void put()(auto ref T input)
    {
        set[input] = [];
    }
    
    ///
    auto opSlice()
    {
        return set.byKey;
    }
    
    ///
    bool opIn_r()(auto ref T v)
    {
        return (v in set) !is null;
    }
    
    ///
    bool opIndex()(auto ref T v)
    {
        return v in this;
    }
    
    ///
    auto dup()
    {
        set.dup;
    }
    
    ///
    void rehash()
    {
        set.rehash;
    }
    
    ///
    void clear()
    {
        set.clear;
    }
}

// temp fix for std.algorithm.copy not having ref dest
@safe copy(R1, R2)(R1 src, auto ref R2 dest)
{
    foreach (e; src)
        dest.put(e);
}

///
@safe unittest
{
    import std.range.primitives;
    static assert(isOutputRange!(Set!int, int));
    Set!int set;

    set.put(1);
    set.put(5);

    assert(1 in set);
    assert(set[5]);
    assert(4 !in set);
}

unittest {
    Set!int set;
    import std.algorithm : each; // not copy
    copy([1, 5, 4], set);
    import std.range;
    assert(set[].walkLength == 3);
    [1,5,4].each!(e => assert(e in set));
    
    set.clear;
    assert(set[].walkLength == 0);
}
