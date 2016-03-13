// Written in the D programming language.

/**
Bit-level manipulation facilities.

Macros:

WIKI = StdBitarray

Copyright: Copyright Digital Mars 2007 - 2011.
License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
Authors:   $(WEB digitalmars.com, Walter Bright),
           $(WEB erdani.org, Andrei Alexandrescu),
           Jonathan M Davis,
           Alex Rønne Petersen,
           Damian Ziemba
Source: $(PHOBOSSRC std/_bitmanip.d)
*/
/*
         Copyright Digital Mars 2007 - 2012.
Distributed under the Boost Software License, Version 1.0.
   (See accompanying file LICENSE_1_0.txt or copy at
         http://www.boost.org/LICENSE_1_0.txt)
*/
module mybitops;

//debug = bitarray;                // uncomment to turn on debugging printf's



private string myToStringx(ulong n)
{
    enum s = "0123456789";
    if (n < 10)
        return s[cast(size_t)n..cast(size_t)n+1];
    else
        return myToStringx(n / 10) ~ myToStringx(n % 10);
}

private string myToString(ulong n)
{
    return myToStringx(n) ~ (n > uint.max ? "UL" : "U");
}

private template createAccessors(
    string store, T, string name, size_t len, size_t offset)
{
    static if (!name.length)
    {
        // No need to create any accessor
        enum result = "";
    }
    else static if (len == 0)
    {
        // Fields of length 0 are always zero
        enum result = "enum "~T.stringof~" "~name~" = 0;\n";
    }
    else
    {
        enum ulong
            maskAllElse = ((~0uL) >> (64 - len)) << offset,
            signBitCheck = 1uL << (len - 1);

        static if (T.min < 0)
        {
            enum long minVal = -(1uL << (len - 1));
            enum ulong maxVal = (1uL << (len - 1)) - 1;
            alias UT = Unsigned!(T);
            enum UT extendSign = cast(UT)~((~0uL) >> (64 - len));
        }
        else
        {
            enum ulong minVal = 0;
            enum ulong maxVal = (~0uL) >> (64 - len);
            enum extendSign = 0;
        }

        static if (is(T == bool))
        {
            static assert(len == 1);
            enum result =
            // getter
                "@property bool " ~ name ~ "() const { return "
                ~"("~store~" & "~myToString(maskAllElse)~") != 0;}\n"
            // setter
                ~"@property void " ~ name ~ "(bool v) {"
                ~"if (v) "~store~" |= "~myToString(maskAllElse)~";"
                ~"else "~store~" &= ~"~myToString(maskAllElse)~";}\n";
        }
        else
        {
            // getter
            enum result = "@property  "~T.stringof~" "~name~"() const { auto result = "
                ~"("~store~" & "
                ~ myToString(maskAllElse) ~ ") >>"
                ~ myToString(offset) ~ ";"
                ~ (T.min < 0
                   ? "if (result >= " ~ myToString(signBitCheck)
                   ~ ") result |= " ~ myToString(extendSign) ~ ";"
                   : "")
                ~ " return cast("~T.stringof~") result;}\n"
            // setter
                ~"@property void "~name~"("~T.stringof~" v) { "
                ~store~" = cast(typeof("~store~"))"
                ~" (("~store~" & ~cast(typeof("~store~"))"~myToString(maskAllElse)~")"
                ~" | ((cast(typeof("~store~")) v << "~myToString(offset)~")"
                ~" & "~myToString(maskAllElse)~"));}\n"
            // constants
                ~"enum "~T.stringof~" "~name~"_min = cast("~T.stringof~")"
                ~myToString(minVal)~"; "
                ~" enum "~T.stringof~" "~name~"_max = cast("~T.stringof~")"
                ~myToString(maxVal)~"; ";
        }
    }
}

private template createStoreName(Ts...)
{
    static if (Ts.length < 2)
        enum createStoreName = "";
    else
        enum createStoreName = "_" ~ Ts[1] ~ createStoreName!(Ts[3 .. $]);
}

private template createFields(string store, size_t offset, Ts...)
{
    static if (!Ts.length)
    {
        static if (offset == ubyte.sizeof * 8)
            alias StoreType = ubyte;
        else static if (offset == ushort.sizeof * 8)
            alias StoreType = ushort;
        else static if (offset == uint.sizeof * 8)
            alias StoreType = uint;
        else static if (offset == ulong.sizeof * 8)
            alias StoreType = ulong;
        else
        {
            static assert(false, "Field widths must sum to 8, 16, 32, or 64");
            alias StoreType = ulong; // just to avoid another error msg
        }
        enum result = "private " ~ StoreType.stringof ~ " " ~ store ~ ";";
    }
    else
    {
        enum result
            = createAccessors!(store, Ts[0], Ts[1], Ts[2], offset).result
            ~ createFields!(store, offset + Ts[2], Ts[3 .. $]).result;
    }
}

/**
Allows creating bit fields inside $(D_PARAM struct)s and $(D_PARAM
class)es.

Example:

----
struct A
{
    int a;
    mixin(bitfields!(
        uint, "x",    2,
        int,  "y",    3,
        uint, "z",    2,
        bool, "flag", 1));
}
A obj;
obj.x = 2;
obj.z = obj.x;
----

The example above creates a bitfield pack of eight bits, which fit in
one $(D_PARAM ubyte). The bitfields are allocated starting from the
least significant bit, i.e. x occupies the two least significant bits
of the bitfields storage.

The sum of all bit lengths in one $(D_PARAM bitfield) instantiation
must be exactly 8, 16, 32, or 64. If padding is needed, just allocate
one bitfield with an empty name.

Example:

----
struct A
{
    mixin(bitfields!(
        bool, "flag1",    1,
        bool, "flag2",    1,
        uint, "",         6));
}
----

The type of a bit field can be any integral type or enumerated
type. The most efficient type to store in bitfields is $(D_PARAM
bool), followed by unsigned types, followed by signed types.
*/

template bitfields(T...)
{
    enum { bitfields = createFields!(createStoreName!(T), 0, T).result }
}
