module mci.core.code.stream;

import mci.core.container,
       mci.core.code.functions,
       mci.core.code.instructions;

public final class InstructionStream : ReadOnlyIndexable!Instruction
{
    private BasicBlock _block;
    private NoNullList!Instruction _instructions;

    invariant()
    {
        assert(_instructions);
        assert(_block);
    }

    package this(BasicBlock block)
    in
    {
        assert(block);
    }
    body
    {
        _block = block;
        _instructions = new typeof(_instructions)();
    }

    @property public BasicBlock block()
    out (result)
    {
        assert(result);
    }
    body
    {
        return _block;
    }

    public final int opApply(scope int delegate(ref Instruction) dg)
    {
        foreach (item; _instructions)
        {
            auto status = dg(item);

            if (status)
                return status;
        }

        return 0;
    }

    public final int opApply(scope int delegate(ref size_t, ref Instruction) dg)
    {
        foreach (i, item; _instructions)
        {
            auto status = dg(i, item);

            if (status)
                return status;
        }

        return 0;
    }

    public final Instruction* opBinaryRight(string op : "in")(Instruction item)
    {
        return item in _instructions;
    }

    public final Instruction opIndex(size_t index)
    {
        return _instructions[index];
    }

    public ReadOnlyIndexable!Instruction opSlice()
    {
        return duplicate();
    }

    public ReadOnlyIndexable!Instruction opSlice(size_t x, size_t y)
    {
        return _instructions[x .. y];
    }

    public ReadOnlyIndexable!Instruction opCat(Iterable!Instruction rhs)
    {
        return _instructions ~ rhs;
    }

    public final override equals_t opEquals(Object o)
    {
        if (this is o)
            return true;

        if (auto stream = cast(InstructionStream)o)
            return _instructions == stream._instructions;

        return false;
    }

    public final override hash_t toHash()
    {
        return typeid(typeof(_instructions)).getHash(&_instructions);
    }

    public final override int opCmp(Object o)
    {
        if (this is o)
            return 0;

        if (auto stream = cast(InstructionStream)o)
            return typeid(typeof(_instructions)).compare(&_instructions, &stream._instructions);

        return 1;
    }

    @property public final size_t count()
    {
        return _instructions.count;
    }

    @property public final bool empty()
    {
        return _instructions.empty;
    }

    public ReadOnlyIndexable!Instruction duplicate()
    {
        return _instructions.duplicate();
    }

    public Instruction append(T ...)(T args)
    {
        auto insn = new Instruction(_block, args);

        _instructions.add(insn);

        return insn;
    }

    public Instruction insertBefore(T ...)(Instruction next, T args)
    in
    {
        assert(next);
        assert(next in _instructions);
    }
    body
    {
        auto insn = new Instruction(_block, args);

        _instructions.insert(findIndex(_instructions, next) - 1, insn);

        return insn;
    }

    public Instruction insertAfter(T ...)(Instruction previous, T args)
    in
    {
        assert(previous);
        assert(previous in _instructions);
    }
    body
    {
        auto insn = new Instruction(_block, args);

        _instructions.insert(findIndex(_instructions, previous) + 1, insn);

        return insn;
    }

    public Instruction replace(T ...)(Instruction old, T args)
    in
    {
        assert(old);
        assert(old in _instructions);
    }
    body
    {
        return _instructions[findIndex(_instructions, old)] = new Instruction(_block, args);
    }

    public void remove(Instruction instruction)
    in
    {
        assert(instruction);
        assert(instruction in _instructions);
    }
    body
    {
        _instructions.remove(instruction);
    }
}