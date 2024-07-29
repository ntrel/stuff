version = x86_64;

struct FooEnum
{
    int A = 5, B = 6;
    version (x86_64) {
        int C = 7;
    } else version (AArch64) {
        int C = 17;
    } else {
        static assert(0);
    }
}

mixin enumGen!(FooEnum, "FOO");

static assert(FOO.A == 5);
static assert(FOO.B == 6);

version (x86_64)
static assert(FOO.C == 7);

template enumGen(T, string name)
{
    private string _gen()
    {
        T v;
        auto r = "enum " ~ name ~ " {";
        foreach (m; __traits(allMembers, T))
        {
            import std.conv;
            r ~= m ~ "=" ~ __traits(getMember, v, m).to!string ~ ",";
        }
        r ~= "}";
        return r;
    }
    mixin(_gen);
}
