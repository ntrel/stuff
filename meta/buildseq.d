SequenceBuilder
	__buildSeq(Identifier, LwrExpression .. UprExpression, Expression)
	__buildSeq(Identifier, SeqExpression, Expression)

alias staticIota(size_t start, size_t end) =
	__buildSeq(i, start..end, i);

__buildSeq(i, 0..3, staticIota!(0, i))
// (0, 0, 1, 0, 1, 2)

alias Map(alias Tem, S...) =
	__buildSeq(E, S, Tem!E);

alias Filter(alias pred, S...) =
	__buildSeq(E, S, pred!E ? E : AliasSeq!());

// in case ternary can't work, but then we instantiate O(n) of Select!
import std.traits : Select;
alias Filter(alias pred, S...) =
	__buildSeq(E, S, Select!(pred!E, E, AliasSeq!()));

/// remainder of std.meta:

alias EraseAll(alias Item, S...) =
	__buildSeq(E, S, Select!(__traits(isSame, E, Item), AliasSeq!(), E));

// search for each element in the sequence constructed so far, __Result
alias NoDuplicates(S...) =
	__buildSeq(E, S, (staticIndexOf!(E, __Result) == -1) ? E : AliasSeq!());

alias Repeat(size_t n, S...) =
	__buildSeq(i, 0..n, S);

alias ReplaceAll(alias T, alias U, S...) =
	__buildSeq(E, S, __traits(isSame, E, T) ? U : E);

template Stride(int stepSize, S...)
if (stepSize != 0)
{
	static if (stepSize > 0)
		alias Stride = __buildSeq(E, S, (i % stepSize == 0) ? S[i] : AliasSeq!());
	else
		alias Stride = __buildSeq(E, S, (i % stepSize == 0) ? S[$ - 1 - i] : AliasSeq!());
}

// these don't use recursion:
// aliasSeqOf, allSatisfy, anySatisfy, staticIndexOf
// Erase, Replace shouldn't use recursion - use staticIndexOf
