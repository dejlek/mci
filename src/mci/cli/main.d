module mci.cli.main;

import core.memory,
       std.stdio,
       std.getopt,
       mci.cli.tool,
       mci.core.common,
       mci.core.config,
       mci.jit.engine,
       mci.optimizer.manager;

static if (isPOSIX)
{
    /**
     * Indicates which garbage collector to use when running program.s
     */
    public enum GarbageCollectorType : ubyte
    {
        dgc, /// Uses DGarbageCollector.
        libc, /// Uses LibCGarbageCollector.
        boehm, /// Uses BoehmGarbageCollector (POSIX only).
    }
}
else
{
    /**
     * Indicates which garbage collector to use when running program.s
     */
    public enum GarbageCollectorType : ubyte
    {
        dgc, /// Uses DGarbageCollector.
        libc, /// Uses LibCGarbageCollector.
    }
}

/**
 * Indicates the strategy to use when the linker encounters name clashes.
 */
public enum LinkerRenameStrategy : ubyte
{
    error, /// Simply error out.
    rename, /// Use a simplistic renaming scheme.
}

private bool silent; /// Indicates whether any console output from MCI should be printed.

/**
 * Runs the command line interface.
 *
 * Params:
 *  args = Arguments from the command line.
 */
private int run(string[] args)
in
{
    assert(args);

    foreach (arg; args)
        assert(arg);
}
body
{
    auto cli = args[0];

    bool help;

    try
    {
        getopt(args,
               config.caseSensitive,
               config.bundling,
               config.passThrough,
               "help|h", &help,
               "silent|s", &silent);
    }
    catch (Exception ex)
    {
        logf("Error: Could not parse command line: %s", ex.msg);
        return 2;
    }

    if (help)
    {
        log("Managed Compiler Infrastructure (MCI) 1.0");
        log("Copyright (c) 2012 The Lycus Foundation - http://lycus.org");
        log("Available under the terms of the MIT License");
        log();

        usage(cli);
        log();

        log("Available tools:");
        log();

        foreach (i, tool; allTools)
        {
            logf("     %s\t%s", tool.x, tool.y.description);

            if (tool.y.options)
            {
                log();

                foreach (line; tool.y.options)
                    logf("     %s", line);
            }

            if (i < allTools.count)
                log();
        }

        log("Available garbage collectors:");
        log();

        logf("     %s\t\t\t\t\tUses the D runtime's garbage collector (default).", GarbageCollectorType.dgc);
        logf("     %s\t\t\t\t\tUses calloc/free; performs no actual collection.", GarbageCollectorType.libc);

        static if (isPOSIX)
            logf("     %s\t\t\t\t\tUses the Boehm-Demers-Weiser garbage collector.", GarbageCollectorType.boehm);

        log();
        log("Available JIT back ends:");
        log();

        logf("     %s\t\t\t\t\tUses the native JIT back end (default).", JITBackEnd.native);
        logf("     %s\t\t\t\t\tUses the statically compiling Clang back end.", JITBackEnd.clang);

        log();
        log("Available optimization passes:");
        log();

        foreach (pass; allOptimizers)
            logf("     %s\t\t\t\t\t%s", pass.name, pass.description);

        log();
        log("Available name clash resolution strategies:");
        log();

        logf("     %s\t\t\t\t\tError out on name clashes (default).", LinkerRenameStrategy.error);
        logf("     %s\t\t\t\t\tUse a simple rename strategy.", LinkerRenameStrategy.rename);

        log();
        log("System configuration:");
        log();

        logf("     Architecture:\t\t\t\t%s", architectureName);
        logf("     Pointer Length:\t\t\t\t%s-bit", is32Bit ? 32 : 64);
        logf("     Endianness:\t\t\t\t%s", endiannessName);
        logf("     Operating System:\t\t\t\t%s", operatingSystemName);
        logf("     Emulation Layer:\t\t\t\t%s", emulationLayerName);
        logf("     Compiler:\t\t\t\t\t%s", compilerName);

        log();

        return 0;
    }

    if (args.length < 2)
    {
        usage(cli);

        return 2;
    }

    auto tool = getTool(args[1]);

    if (!tool)
    {
        logf("Error: No such tool: '%s'", args[1]);
        return 2;
    }

    return tool.run(args[1 .. $]);
}

/**
 * Writes the usage hint to the console.
 *
 * Params:
 *  cli = Name of the command line interface executable.
 */
private void usage(string cli)
in
{
    assert(cli);
}
body
{
    logf("Usage: %s [--help|-h] [--silent|-s] <tool> <args>", cli);
}

public void log(T ...)(T args)
{
    if (!silent)
        writeln(args);
}

public void logf(T ...)(T args)
in
{
    static assert(T.length);
}
body
{
    if (!silent)
        writefln(args);
}

private int main(string[] args)
in
{
    assert(args);

    foreach (arg; args)
        assert(arg);
}
body
{
    scope (exit)
        GC.collect();

    return run(args);
}
