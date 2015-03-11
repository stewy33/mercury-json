%-----------------------------------------------------------------------------%
% vim: ft=mercury ts=4 sw=4 et
%-----------------------------------------------------------------------------%
% Copyright (C) 2013-2015 Julien Fischer.
% All rights reserved.
%
% Author: Julien Fischer <jfischer@opturion.com>
%
% This module implements marshaling of Mercury values to JSON.
%
%-----------------------------------------------------------------------------%

:- module json.marshal.
:- interface.

%-----------------------------------------------------------------------------%

:- func int_to_json(int) = json.value.
:- func float_to_json(float) = json.value.
:- func string_to_json(string) = json.value.
:- func char_to_json(char) = json.value.
:- func bool_to_json(bool) = json.value.
:- func integer_to_json(integer) = json.value.
:- func date_time_to_json(date) = json.value.
:- func duration_to_json(duration) = json.value.
:- func pair_to_json(pair(A, B)) = json.value <= (to_json(A), to_json(B)).
:- func list_to_json(list(T)) = json.value <= to_json(T).
:- func cord_to_json(cord(T)) = json.value <= to_json(T).
:- func array_to_json(array(T)) = json.value <= to_json(T).
:- func version_array_to_json(version_array(T)) = json.value <= to_json(T).
:- func bitmap_to_json(bitmap) = json.value.
:- func set_ordlist_to_json(set_ordlist(T)) = json.value <= to_json(T).
:- func set_unordlist_to_json(set_unordlist(T)) = json.value <= to_json(T).
:- func set_tree234_to_json(set_tree234(T)) = json.value <= to_json(T).
:- func set_ctree234_to_json(set_ctree234(T)) = json.value <= to_json(T).
:- func set_bbbtree_to_json(set_bbbtree(T)) = json.value <= to_json(T).
:- func maybe_to_json(maybe(T)) = json.value <= to_json(T).
:- func map_to_json(map(K, V)) = json.value <= (to_json(K), to_json(V)).
:- func bimap_to_json(bimap(K, V)) = json.value <= (to_json(K), to_json(V)).

%:- func marshal_from_type(T) = maybe_error(json.value).

%-----------------------------------------------------------------------------%
%-----------------------------------------------------------------------------%

:- implementation.

:- import_module exception.

%-----------------------------------------------------------------------------%

int_to_json(Int) = number(float(Int)).

float_to_json(Float) =
    ( if is_nan_or_inf(Float)
    then throw(non_finite_number_error("to_json/1"))
    else number(Float)
    ).

string_to_json(String) = string(String).

char_to_json(Char) = string(string.from_char(Char)).

bool_to_json(Bool) = bool(Bool).

integer_to_json(Integer) = Value :-
    IntegerString : string = integer.to_string(Integer),
    Value = string(IntegerString).

date_time_to_json(DateTime) = string(date_to_string(DateTime)).

duration_to_json(Duration) = string(duration_to_string(Duration)).

pair_to_json(Pair) = Value :-
    Pair = Fst - Snd,
    FstValue = to_json(Fst),
    SndValue = to_json(Snd),
    Value = json.det_make_object([
        "fst" - FstValue,
        "snd" - SndValue
    ]).

list_to_json(List) = Value :-
    list_to_values(List, [], RevValues),
    list.reverse(RevValues, Values),
    Value = array(Values).

:- pred list_to_values(list(T)::in,
    list(value)::in, list(value)::out) is det <= to_json(T).

list_to_values([], !Values).
list_to_values([T | Ts], !Values) :-
    Value = to_json(T),
    !:Values = [Value | !.Values],
    list_to_values(Ts, !Values).

cord_to_json(Cord) = Result :-
    List = cord.list(Cord),
    Result = list_to_json(List).

array_to_json(Array) = Value :-
    array_to_values(Array, array.min(Array), array.max(Array), [], Values),
    Value = array(Values).

:- pred array_to_values(array(T)::in, int::in, int::in,
    list(value)::in, list(value)::out) is det <= to_json(T).

array_to_values(Array, Min, I, !Values) :-
    ( if I < Min then
        true
    else
        Elem = Array ^ unsafe_elem(I),
        Value = to_json(Elem),
        !:Values = [Value | !.Values],
        array_to_values(Array, Min, I - 1, !Values)
    ).

version_array_to_json(VersionArray) = Value :-
    version_array_to_values(VersionArray, 0, version_array.max(VersionArray),
        [], Values),
    Value = array(Values).

:- pred version_array_to_values(version_array(T)::in, int::in, int::in,
    list(value)::in, list(value)::out) is det <= to_json(T).

version_array_to_values(Array, Min, I, !Values) :-
    ( if I < Min then
        true
    else
        Elem = version_array.lookup(Array, I),
        Value = to_json(Elem),
        !:Values = [Value | !.Values],
        version_array_to_values(Array, Min, I - 1, !Values)
    ).

bitmap_to_json(Bitmap) = Value :-
    String = bitmap.to_string(Bitmap),
    Value = string(String).

set_ordlist_to_json(Set) = Result :-
    set_ordlist.to_sorted_list(Set, List),
    Result = list_to_json(List).

set_unordlist_to_json(Set) = Result :-
    set_unordlist.to_sorted_list(Set, List),
    Result = list_to_json(List).

set_tree234_to_json(Set) = Result :-
    set_tree234.to_sorted_list(Set, List),
    Result = list_to_json(List).

set_ctree234_to_json(Set) = Result :-
    List = set_ctree234.to_sorted_list(Set),
    Result = list_to_json(List).

set_bbbtree_to_json(Set) = Result :-
    set_bbbtree.to_sorted_list(Set, List),
    Result = list_to_json(List).

maybe_to_json(Maybe) = Value :-
    (
        Maybe = no,
        Value = null
    ;
        Maybe = yes(Arg),
        Value = to_json(Arg)
    ).

map_to_json(Map) = Value :-
    map.to_assoc_list(Map, KVs),
    Value = to_json(KVs).

bimap_to_json(Bimap) = Value :-
    bimap.to_assoc_list(Bimap, KVs),
    Value = to_json(KVs).

%-----------------------------------------------------------------------------%
:- end_module json.marshal.
%-----------------------------------------------------------------------------%
