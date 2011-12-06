module mci.core.diagnostics.debugging;

import std.conv;

public final class SourceLocation
{
    private uint _line;
    private uint _column;

    invariant()
    {
        assert(_line);
    }

    public this(uint line, uint column = 0)
    in
    {
        assert(line);
    }
    body
    {
        _line = line;
        _column = column;
    }

    @property public uint line()
    out (result)
    {
        assert(result);
    }
    body
    {
        return _line;
    }

    @property public uint column()
    {
        return _column;
    }

    public override string toString()
    {
        return "(line " ~ to!string(_line) ~ (_column == 0 ? "" : ", column " ~ to!string(_column)) ~ ")";
    }
}
