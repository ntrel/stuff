struct S {
    int[] data;
    
    static struct Expr(T...)
    {
        T items;
        
        static foreach (E; T)
            static assert(is(E == S));

        // concat(items) ~ rhs
        S opBinary(string op : "~")(S rhs) {
            auto len = rhs.data.length;
            foreach (s; items)
                len += s.data.length;
            auto r = new int[len];
            
            size_t i;
            foreach (s; items)
            {
                r[i..$][0..s.data.length] = s.data;
                i += s.data.length;
            }
            r[i..$] = rhs.data;
            return S(r);
        }
        auto opBinaryTemp(string op : "~")(S rhs) {
            return expr(items, rhs);
        }
    }
    private static expr(T...)(T args)
    {
        return Expr!T(args);
    }
    auto opBinaryTemp(string op : "~")(S rhs) {
        return expr(this, rhs);
    }
    // this ~ rhs
    S opBinary(string op : "~")(S rhs) {
        return S(data ~ rhs.data);
    }
}

void main()
{
    import std.stdio;

    auto s1 = S([1,10]);
    auto s2 = S([2,22]);
    auto s3 = S([3,-3]);
    //s1 ~ s2
    s1.opBinary!"~"(s2).data.writeln;
    //s1 ~ s2 ~ s3
    s1.opBinaryTemp!"~"(s2).opBinary!"~"(s3).data.writeln;
    //s1 ~ s2 ~ s3 ~ s1
    s1.opBinaryTemp!"~"(s2).opBinaryTemp!"~"(s3).opBinary!"~"(s1).data.writeln;
    
    auto t1 = s1.opBinaryTemp!"~"(s2);
    pragma(msg, typeof(t1));
    auto t2 = t1.opBinaryTemp!"~"(s3);
    pragma(msg, typeof(t2));
    auto r = t2.opBinary!"~"(s1);
    pragma(msg, typeof(r));
}
