module mci.assembler.disassembly.modules;

import mci.core.container,
       mci.core.io,
       mci.core.tuple,
       mci.core.code.functions,
       mci.core.code.instructions,
       mci.core.code.modules,
       mci.core.code.opcodes,
       mci.core.typing.members,
       mci.core.typing.types;

public final class ModuleDisassembler
{
    private Stream _stream;
    private TextWriter _writer;
    private bool _done;

    invariant()
    {
        assert(_stream);
        assert(_stream.canWrite);
        assert(!_stream.isClosed);
        assert(_writer);
    }

    public this(Stream stream)
    in
    {
        assert(stream);
        assert(stream.canWrite);
        assert(!stream.isClosed);
    }
    body
    {
        _stream = stream;
        _writer = new typeof(_writer)(stream);
    }

    public void disassemble(Module module_)
    in
    {
        assert(module_);
        assert(!_done);
    }
    body
    {
        _done = true;

        foreach (type; module_.types)
            writeType(type.y);

        foreach (func; module_.functions)
            writeFunction(func.y);
    }

    private void writeType(StructureType type)
    in
    {
        assert(type);
    }
    body
    {
        _writer.writef("type %s", type.name);

        if (type.alignment)
            _writer.writef(" align %s", type.alignment);

        _writer.writeln();
        _writer.writeln("{");

        foreach (field; type.fields)
        {
            _writer.write("    field ");

            final switch (field.y.storage)
            {
                case FieldStorage.instance:
                    _writer.write("instance");
                    break;
                case FieldStorage.static_:
                    _writer.write("static");
                    break;
                case FieldStorage.thread:
                    _writer.write("thread");
                    break;
            }

            _writer.writefln(" %s %s;", field.y.type, field.y.name);
        }

        _writer.writeln("}");
        _writer.writeln();
    }

    private void writeFunction(Function function_)
    in
    {
        assert(function_);
    }
    body
    {
        _writer.write("function ");

        if (function_.attributes & FunctionAttributes.ssa)
            _writer.write("ssa ");

        if (function_.attributes & FunctionAttributes.pure_)
            _writer.write("pure ");

        if (function_.attributes & FunctionAttributes.noOptimization)
            _writer.write("nooptimize ");

        if (function_.attributes & FunctionAttributes.noInlining)
            _writer.write("noinline ");

        _writer.writef("%s %s (", function_.returnType ? function_.returnType.toString() : "void", function_.name);

        foreach (i, param; function_.parameters)
        {
            _writer.write(param.type);

            if (i < function_.parameters.count - 1)
                _writer.write(", ");
        }

        _writer.writeln(")");

        final switch (function_.callingConvention)
        {
            case CallingConvention.standard:
                break;
            case CallingConvention.cdecl:
                _writer.write(" cdecl");
                break;
            case CallingConvention.stdCall:
                _writer.write(" stdcall");
                break;
        }

        _writer.writeln("{");

        foreach (reg; function_.registers)
            _writer.writefln("    register %s %s;", reg.y.type, reg.y.name);

        _writer.writeln();

        foreach (block; function_.blocks)
        {
            _writer.writef("    block %s", block.y.name);

            if (block.y.unwindBlock)
                _writer.writef(" unwind %s", block.y.unwindBlock.name);

            _writer.writeln();
            _writer.writeln("    {");

            foreach (instr; block.y.stream)
            {
                if (!instr.metadata.empty)
                {
                    _writer.write("[");

                    foreach (i, md; instr.metadata)
                    {
                        _writer.writef("'%s' : '%s'", md.key, md.value);

                        if (i != instr.metadata.count - 1)
                            _writer.writeln(",");
                    }

                    _writer.writeln("]");
                }

                _writer.writeln("        %s;", instr);
            }

            _writer.writeln("    }");
            _writer.writeln();
        }

        _writer.writeln("}");
        _writer.writeln();
    }
}
