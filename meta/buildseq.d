SequenceBuilder
	__buildSeq(Identifier, RangeExpression, Expression)
	__buildSeq(Identifier, Identifier, Expression)

alias staticIota(size_t start, size_t end) =
	__buildSeq(i, start..end, i);

alias Map(alias Tem, S...) =
	__buildSeq(E, S, Tem!E);

__buildSeq(i, 0..3, staticIota!(0, i))
// (0, 0, 1, 0, 1, 2)

alias Filter(alias pred, S...) =
	__buildSeq(E, S, pred!E ? E : AliasSeq!());

import std.traits : Select;
alias Filter(alias pred, S...) =
	__buildSeq(E, S, Select!(pred!E, E, AliasSeq!()));

alias EraseAll(alias Item, S...) =
	__buildSeq(E, S, Select!(__traits(isSame, E, Item), AliasSeq!(), E));
