module mci.vm.exception;

import mci.core.exception,
       mci.core.code.instructions,
       mci.vm.execution,
       mci.vm.trace;

/**
 * The exception that an $(D ExecutionEngine) will throw
 * if the executed program throws an unhandled exception.
 */
public class ExecutionException : CompilerException
{
    private StackTrace _trace;
    private RuntimeValue _exception;

    pure nothrow invariant()
    {
        assert(_trace);
        assert(_exception);
    }

    public this(StackTrace trace, RuntimeValue exception, string msg, string file = __FILE__, size_t line = __LINE__)
    in
    {
        assert(trace);
        assert(exception);
        assert(msg);
        assert(file);
        assert(line);
    }
    body
    {
        super(msg, file, line);

        _trace = trace;
        _exception = exception;
    }

    public this(StackTrace trace, RuntimeValue exception, string msg, Throwable next, string file = __FILE__, size_t line = __LINE__)
    in
    {
        assert(trace);
        assert(exception);
        assert(msg);
        assert(next);
        assert(file);
        assert(line);
    }
    body
    {
        super(msg, next, file, line);

        _trace = trace;
        _exception = exception;
    }

    /**
     * Gets the stack trace of the exception.
     *
     * Returns:
     *  The stack trace of the exception.
     */
    @property public StackTrace trace() pure nothrow
    out (result)
    {
        assert(result);
    }
    body
    {
        return _trace;
    }

    /**
     * Gets the actual exception object the program threw.
     *
     * Returns:
     *  The exception object the program threw.
     */
    @property public RuntimeValue exception() pure nothrow
    out (result)
    {
        assert(result);
    }
    body
    {
        return _exception;
    }
}
