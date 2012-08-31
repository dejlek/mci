module mci.compiler.clang.generator;

import mci.compiler.clang.compiler,
       mci.compiler.clang.functions,
       mci.core.container,
       mci.core.io,
       mci.core.tuple,
       mci.core.code.functions,
       mci.core.typing.members,
       mci.core.typing.types;

/**
 * Generates Clang-compatible C99 code from IAL. The emitted code
 * is only valid for the given $(D ClangCompiler)'s $(D ExecutionEngine)
 * and the current process.
 */
public final class ClangCGenerator
{
    private ClangCompiler _compiler;
    private Stream _stream;
    private TextWriter _writer;
    private ArrayQueue!Function _functionQueue;
    private ArrayQueue!StructureType _typeQueue;
    private ArrayQueue!StaticArrayType _arrayQueue;
    private NoNullDictionary!(Function, string, false) _functionNames;
    private NoNullDictionary!(Field, string, false) _fieldNames;
    private bool _done;

    invariant()
    {
        assert(_compiler);
        assert(_stream);
        assert((cast()_stream).canWrite);
        assert(!(cast()_stream).isClosed);
        assert(_writer);
        assert(_functionQueue);
        assert(_typeQueue);
        assert(_arrayQueue);
        assert(_functionNames);
        assert(_fieldNames);
    }

    /**
     * Constructs a new $(D ClangCGenerator) instance.
     *
     * Params:
     *  compiler = The $(D ClangCompiler) instance to generate code for.
     *  stream = The stream to write to.
     */
    public this(ClangCompiler compiler, Stream stream) nothrow
    in
    {
        assert(compiler);
        assert(stream);
        assert((cast()stream).canWrite);
        assert(!(cast()stream).isClosed);
    }
    body
    {
        _compiler = compiler;
        _stream = stream;
        _writer = new typeof(_writer)(stream);
        _functionQueue = new typeof(_functionQueue)();
        _typeQueue = new typeof(_typeQueue)();
        _arrayQueue = new typeof(_arrayQueue)();
        _functionNames = new typeof(_functionNames)();
        _fieldNames = new typeof(_fieldNames)();
    }

    @property public ClangCompiler compiler() pure nothrow
    out (result)
    {
        assert(result);
    }
    body
    {
        return _compiler;
    }

    @property public Stream stream() pure nothrow
    out (result)
    {
        assert(result);
    }
    body
    {
        return _stream;
    }

    @property package TextWriter writer() pure nothrow
    out (result)
    {
        assert(result);
    }
    body
    {
        return _writer;
    }

    @property package ArrayQueue!Function functionQueue() pure nothrow
    out (result)
    {
        assert(result);
    }
    body
    {
        return _functionQueue;
    }

    @property package ArrayQueue!StructureType typeQueue() pure nothrow
    out (result)
    {
        assert(result);
    }
    body
    {
        return _typeQueue;
    }

    @property package ArrayQueue!StaticArrayType arrayQueue() pure nothrow
    out (result)
    {
        assert(result);
    }
    body
    {
        return _arrayQueue;
    }

    @property package NoNullDictionary!(Function, string, false) functionNames() pure nothrow
    out (result)
    {
        assert(result);
    }
    body
    {
        return _functionNames;
    }

    @property package NoNullDictionary!(Field, string, false) fieldNames() pure nothrow
    out (result)
    {
        assert(result);
    }
    body
    {
        return _fieldNames;
    }

    /**
     * Generates C99 code for a function.
     *
     * This actually generates code for all functions that
     * $(D function_) could possibly end up calling.
     *
     * Params:
     *  function_ = The function to generate C99 code for.
     *
     * Returns:
     *  A tuple containing static field and function name mappings.
     */
    public Tuple!(Lookup!(Field, string), Lookup!(Function, string)) write(Function function_)
    in
    {
        assert(function_);
        assert(!_done);
    }
    body
    {
        _done = true;

        _functionQueue.enqueue(function_);

        while (!_functionQueue.empty)
            writeFunction(this, _functionQueue.dequeue());

        // TODO: Reset to position 0 and emit types and function declarations.

        return tuple!(Lookup!(Field, string), Lookup!(Function, string))(_fieldNames, _functionNames);
    }
}