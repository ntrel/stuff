StaticForeachExpr
	static foreach(Identifier; LwrExpression .. UprExpression; Expression)
	static foreach(Identifier; SeqExpression; Expression)

alias staticIota(size_t start, size_t end) =
	static foreach(i; start..end; i);

static foreach(i; 0..3; staticIota!(0, i))
// (0, 0, 1, 0, 1, 2)

alias Map(alias Tem, S...) =
	static foreach(E; S; Tem!E);

// Note: AliasSeq instantiation is intercepted in dmd master
alias Filter(alias pred, S...) =
	static foreach(E; S; AliasSeq!E[0..pred!E]);

/// remainder of std.meta:

alias EraseAll(alias Item, S...) =
	static foreach(E; S; AliasSeq!E[0..!isSame!(E, Item)]);

// search for each element in the unique elements found so far: __Result
// Note: maybe worse complexity O(n^2) than std.meta
alias NoDuplicates(S...) =
	static foreach(E; S; AliasSeq!E[0..staticIndexOf!(E, __Result) == -1]);

alias Repeat(size_t n, S...) =
	static foreach(i; 0..n; S);

alias ReplaceAll(alias T, alias U, S...) =
	static foreach(E; S; AliasSeq!(E, U)[isSame!(E, T)]);

alias Reverse(S...) =
	static foreach(i; 0..S.length; S[$ - 1 - i]);

template Stride(int stepSize, S...)
if (stepSize != 0)
{
	static if (stepSize > 0)
		alias Stride = static foreach(E; S; AliasSeq!(S[i])[0..i % stepSize == 0]);
	else
		alias Stride = static foreach(E; S; AliasSeq!(S[$ - 1 - i])[0..i % stepSize == 0]);
}

// these don't use recursion:
// aliasSeqOf, allSatisfy, anySatisfy, staticIndexOf
// Erase, Replace shouldn't use recursion - use staticIndexOf
