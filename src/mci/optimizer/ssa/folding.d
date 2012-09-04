module mci.optimizer.ssa.folding;

import mci.core.common,
       mci.core.container,
       mci.core.nullable,
       mci.core.analysis.constant,
       mci.core.analysis.utilities,
       mci.core.code.functions,
       mci.core.code.instructions,
       mci.core.code.opcodes,
       mci.core.typing.core,
       mci.optimizer.base;

private OpCode typeToConstantLoadOpCode(CoreType type)
in
{
    assert(type);
}
out (result)
{
    assert(result);
}
body
{
    return match(type,
                 (Int8Type t) => opLoadI8,
                 (UInt8Type t) => opLoadUI8,
                 (Int16Type t) => opLoadI16,
                 (UInt16Type t) => opLoadUI16,
                 (Int32Type t) => opLoadI32,
                 (UInt32Type t) => opLoadUI32,
                 (Int64Type t) => opLoadI64,
                 (UInt64Type t) => opLoadUI64,
                 (Float32Type t) => opLoadF32,
                 (Float64Type t) => opLoadF64);
}

private Constant operandToConstant(InstructionOperand operand)
in
{
    assert(operand.hasValue);
}
body
{
    return match(operand,
                 (byte v) => Constant(cast(long)v),
                 (ubyte v) => Constant(cast(ulong)v),
                 (short v) => Constant(cast(long)v),
                 (ushort v) => Constant(cast(ulong)v),
                 (int v) => Constant(cast(long)v),
                 (uint v) => Constant(cast(ulong)v),
                 (long v) => Constant(v),
                 (ulong v) => Constant(v),
                 (float v) => Constant(v),
                 (double v) => Constant(v));
}

private InstructionOperand constantToOperand(Constant constant, CoreType type)
in
{
    assert(type);
}
out (result)
{
    assert(result.hasValue);
}
body
{
    InstructionOperand operand;

    match(type,
          (Int8Type t) => operand = constant.castTo!byte(),
          (UInt8Type t) => operand = constant.castTo!ubyte(),
          (Int16Type t) => operand = constant.castTo!short(),
          (UInt16Type t) => operand = constant.castTo!ushort(),
          (Int32Type t) => operand = constant.castTo!int(),
          (UInt32Type t) => operand = constant.castTo!uint(),
          (Int64Type t) => operand = constant.castTo!long(),
          (UInt64Type t) => operand = constant.castTo!ulong(),
          (Float32Type t) => operand = constant.castTo!float(),
          (Float64Type t) => operand = constant.castTo!double());

    return operand;
}

private bool isFoldable(Instruction instruction)
in
{
    assert(instruction);
}
body
{
    // Avoid folding native integers.
    foreach (reg; instruction.registers)
        if (reg.type is NativeIntType.instance || reg.type is NativeUIntType.instance)
            return false;

    if (instruction.opCode !is opAriAdd &&
        instruction.opCode !is opAriSub &&
        instruction.opCode !is opAriMul &&
        instruction.opCode !is opAriDiv &&
        instruction.opCode !is opAriRem &&
        instruction.opCode !is opAriNeg &&
        instruction.opCode !is opBitAnd &&
        instruction.opCode !is opBitOr &&
        instruction.opCode !is opBitXOr &&
        instruction.opCode !is opBitNeg &&
        instruction.opCode !is opNot)
        return false;

    return all(instruction.sourceRegisters, (Register r) => isConstantLoad(first(r.definitions).opCode));
}

/**
 * Performs folding of operations on constant values.
 *
 * Only simple ALU operations are folded; that is, constants are
 * not propagated in comparisons and no abstract interpretation
 * is done.
 */
public final class ConstantFolder : OptimizerDefinition
{
    @property public override string name() pure nothrow
    {
        return "const-fold";
    }

    @property public override string description() pure nothrow
    {
        return "Folds constant computations.";
    }

    @property public override PassType type() pure nothrow
    {
        return PassType.ssa;
    }

    public override OptimizerPass create() pure nothrow
    {
        return new class OptimizerPass
        {
            public override void optimize(Function function_)
            {
                auto constantInsns = true;

                while (constantInsns)
                {
                    auto constantLoads = new NoNullList!Instruction();

                    foreach (bb; function_.blocks)
                        addRange(constantLoads, filter(bb.y.stream, (Instruction i) => isConstantLoad(i.opCode)));

                    auto constantOps = new NoNullList!Instruction();

                    foreach (bb; function_.blocks)
                        foreach (instr; bb.y.stream)
                            if (isFoldable(instr))
                                constantOps.add(instr);

                    auto insns = constantOps.duplicate();

                    foreach (instr; insns)
                    {
                        auto result = nullable(Constant.init);
                        auto r1 = operandToConstant(first(instr.sourceRegister1.definitions).operand);
                        auto r2 = Constant.init;
                        auto r3 = Constant.init;

                        if (instr.sourceRegister2)
                            r2 = operandToConstant(first(instr.sourceRegister2.definitions).operand);

                        if (instr.sourceRegister3)
                            r3 = operandToConstant(first(instr.sourceRegister3.definitions).operand);

                        if (instr.opCode is opAriAdd)
                            result = nullable(r1 + r2);
                        else if (instr.opCode is opAriSub)
                            result = nullable(r1 - r2);
                        else if (instr.opCode is opAriMul)
                            result = nullable(r1 * r2);
                        else if (instr.opCode is opAriDiv)
                        {
                            // We can't handle division by zero in any sane fashion, so we simply stop folding.
                            if (cast(IntegerType)instr.targetRegister.type && r2.castTo!ulong() == 0)
                                constantOps.remove(instr);
                            else
                                result = nullable(r1 / r2);
                        }
                        else if (instr.opCode is opAriRem)
                        {
                            // We can't handle division by zero in any sane fashion, so we simply stop folding.
                            if (cast(IntegerType)instr.targetRegister.type && r2.castTo!ulong() == 0)
                                constantOps.remove(instr);
                            else
                                result = nullable(r1 % r2);
                        }
                        else if (instr.opCode is opAriNeg)
                            result = nullable(-r1);
                        else if (instr.opCode is opBitAnd)
                            result = nullable(r1 & r2);
                        else if (instr.opCode is opBitOr)
                            result = nullable(r1 | r2);
                        else if (instr.opCode is opBitXOr)
                            result = nullable(r1 ^ r2);
                        else if (instr.opCode is opBitNeg)
                            result = nullable(~r1);
                        else if (instr.opCode is opNot)
                            result = nullable(r1.not());

                        if (result)
                            instr.block.stream.replace(instr, typeToConstantLoadOpCode(cast(CoreType)instr.targetRegister.type),
                                                       InstructionAttributes.none,
                                                       constantToOperand(result.value, cast(CoreType)instr.targetRegister.type),
                                                       instr.targetRegister, null, null, null);
                    }

                    // Kill constant loads that are no longer used. This includes those
                    // that were never used to begin with and those that are now rendered
                    // useless due to constant folding.
                    foreach (instr; constantLoads)
                        if (instr.targetRegister.uses.empty)
                            instr.block.stream.remove(instr);

                    constantInsns = !constantOps.empty;
                }
            }
        };
    }
}
