module mci.vm.memory.prettyprint;

import std.ascii,
       std.conv,
       std.string,
       mci.core.common,
       mci.core.container,
       mci.core.typing.core,
       mci.core.typing.members,
       mci.core.typing.types,
       mci.vm.memory.layout;

private final class PrettyPrinter
{
    private ulong _indent;
    private string _result;

    private string append(string s)
    in
    {
        assert(s);
    }
    body
    {
        return _result ~= s;
    }

    private string indent()
    {
        for (auto i = 0; i < _indent; i++)
            append("    ");

        return _result;
    }

    private string beginBlock()
    {
        newLine();
        append("{");
        _indent++;

        return _result;
    }

    private string endBlock()
    {
        _indent--;
        newLine();
        append("}");

        return _result;
    }

    private string newLine()
    {
        append(std.ascii.newline);
        indent();

        return _result;
    }

    private string appendLine(string s)
    in
    {
        assert(s);
    }
    body
    {
        append(s);
        newLine();

        return _result;
    }

    public string process(Type type, ubyte* mem, bool is32Bit, string instanceName)
    in
    {
        assert(type);
        assert(mem);
    }
    body
    {
        append(format("[%s] ", type.name));

        if (instanceName.length)
            append(instanceName ~ ": ");

        if (isType!Int8Type(type))
            return append(format("%s", *cast(byte*)mem));
        else if (isType!UInt8Type(type))
            return append(format("%s", *cast(ubyte*)mem));
        else if (isType!Int16Type(type))
            return append(format("%s", *cast(short*)mem));
        else if (isType!UInt16Type(type))
            return append(format("%s", *cast(ushort*)mem));
        else if (isType!Int32Type(type))
            return append(format("%s", *cast(int*)mem));
        else if (isType!UInt32Type(type))
            return append(format("%s", *cast(uint*)mem));
        else if (isType!Int64Type(type))
            return append(format("%s", *cast(long*)mem));
        else if (isType!UInt64Type(type))
            return append(format("%s", *cast(ulong*)mem));
        else if (isType!Float32Type(type))
            return append(format("%s", *cast(float*)mem));
        else if (isType!Float64Type(type))
            return append(format("%s", *cast(double*)mem));
        else if (isType!NativeIntType(type))
            return append(format("%s", *cast(isize_t*)mem));
        else if (isType!NativeUIntType(type))
            return append(format("%s", *cast(size_t*)mem));
        else if (auto struc = cast(StructureType)type)
        {
            beginBlock();

            foreach (field; struc.fields)
            {
                newLine();

                auto offset = computeOffset(field.y, is32Bit);
                process(field.y.type, mem + offset, is32Bit, field.x);
            }

            return endBlock();
        }
        else if (auto vect = cast(VectorType)type)
        {
            auto elementSize = computeSize(vect.elementType, is32Bit);
            auto p = *cast(ubyte**)mem;

            beginBlock();

            for (auto i = 0; i < vect.elements; i++)
            {
                newLine();
                process(vect.elementType, p, is32Bit, to!string(i));

                p += elementSize;
            }

            return endBlock();
        }
        else // Pointers, arrays, and function pointers.
            return append(format("0x%s", *cast(void**)mem));
    }
}

public string prettyPrint(Type type, bool is32Bit, ubyte* mem, string instanceName)
in
{
    assert(type);
    assert(mem);
}
out (result)
{
    assert(result);
}
body
{
    return (new PrettyPrinter()).process(type, mem, is32Bit, instanceName);
}