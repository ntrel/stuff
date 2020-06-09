FoldExpression:
    __Fold(ElemIdentifier, AccIdentifier, NextExpression, SeqExpression, SeedExpression$(OPT))

alias Filter(alias pred, S...) =
    __Fold(E, Acc, AliasSeq!(Acc, AliasSeq!E[0..pred!E]), S, AliasSeq!());

alias Fold(alias Tem, S...) =
    __Fold(E, Acc, Tem!(E, Acc), S);

alias Map(alias Tem, S...) =
    __Fold(E, Acc, AliasSeq!(Acc, Tem!E), S, AliasSeq!());

alias NoDuplicates(S...) =
    __Fold(E, Acc, AliasSeq!(Acc, AliasSeq!E[0..staticIndexOf!(E, Acc) == -1]), S);

alias Repeat(size_t n, S...) =
    __Fold(E, Acc, AliasSeq!(Acc, S), S, AliasSeq!());

