struct S {
    int[] data;
    
    struct Expr {
        S left, right;

        // left ~ right ~ rhs
        S opBinary(string op : "~")(S rhs) {
            size_t lhsLen = left.data.length + right.data.length;
            auto r = new int[lhsLen + rhs.data.length];
            
            r[0..left.data.length] = left.data;
            r[left.data.length..$][0..right.data.length] = right.data;
            r[lhsLen..$][0..rhs.data.length] = rhs.data;
            return S(r);
        }
    }
    Expr opBinaryTemp(string op : "~")(S rhs) {
        return Expr(this, rhs);
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
    auto s2 = S([2,22,222]);
    auto s3 = S([-3,3]);
    //s1 ~ s2 ~ s3
    s1.opBinaryTemp!"~"(s2).opBinary!"~"(s3).data.writeln;
}
