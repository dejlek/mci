module mci.assembler.parsing.ast;

import std.conv,
       std.variant,
       mci.core.container,
       mci.core.nullable,
       mci.core.tuple,
       mci.core.code.functions,
       mci.core.code.opcodes,
       mci.core.diagnostics.debugging,
       mci.core.typing.members,
       mci.core.typing.types;

public abstract class Node
{
    private SourceLocation _location;

    invariant()
    {
        assert(_location);
    }

    protected this(SourceLocation location)
    in
    {
        assert(location);
    }
    body
    {
        _location = location;
    }

    @property public final SourceLocation location()
    {
        return _location;
    }

    @property public ReadOnlyIndexable!Node children()
    {
        return new List!Node();
    }

    public override string toString()
    {
        return "";
    }
}

public abstract class DeclarationNode : Node
{
    protected this(SourceLocation location)
    in
    {
        assert(location);
    }
    body
    {
        super(location);
    }
}

public class SimpleNameNode : Node
{
    private string _name;

    invariant()
    {
        assert(_name);
    }

    public this(SourceLocation location, string name)
    in
    {
        assert(location);
        assert(name);
    }
    body
    {
        super(location);

        _name = name;
    }

    @property public final string name()
    {
        return _name;
    }

    public override string toString()
    {
        return "name: " ~ _name;
    }
}

public class ModuleReferenceNode : Node
{
    private SimpleNameNode _name;

    invariant()
    {
        assert(_name);
    }

    public this(SourceLocation location, SimpleNameNode name)
    in
    {
        assert(location);
        assert(name);
    }
    body
    {
        super(location);

        _name = name;
    }

    @property public final SimpleNameNode name()
    {
        return _name;
    }

    @property public override ReadOnlyIndexable!Node children()
    {
        return toReadOnlyIndexable!Node(_name);
    }
}

public abstract class TypeReferenceNode : Node
{
    public this(SourceLocation location)
    in
    {
        assert(location);
    }
    body
    {
        super(location);
    }
}

public class StructureTypeReferenceNode : TypeReferenceNode
{
    private ModuleReferenceNode _moduleName;
    private SimpleNameNode _name;

    invariant()
    {
        assert(_name);
    }

    public this(SourceLocation location, ModuleReferenceNode moduleName, SimpleNameNode name)
    in
    {
        assert(location);
        assert(name);
    }
    body
    {
        super(location);

        _moduleName = moduleName;
        _name = name;
    }

    @property public final ModuleReferenceNode moduleName()
    {
        return _moduleName;
    }

    @property public final SimpleNameNode name()
    {
        return _name;
    }

    @property public override ReadOnlyIndexable!Node children()
    {
        return toReadOnlyIndexable!Node(_moduleName, _name);
    }
}

public class PointerTypeReferenceNode : TypeReferenceNode
{
    private TypeReferenceNode _elementType;

    invariant()
    {
        assert(_elementType);
    }

    public this(SourceLocation location, TypeReferenceNode elementType)
    in
    {
        assert(location);
        assert(elementType);
    }
    body
    {
        super(location);

        _elementType = elementType;
    }

    @property public final TypeReferenceNode elementType()
    {
        return _elementType;
    }

    @property public override ReadOnlyIndexable!Node children()
    {
        return toReadOnlyIndexable!Node(_elementType);
    }
}

public class ArrayTypeReferenceNode : TypeReferenceNode
{
    private TypeReferenceNode _elementType;

    invariant()
    {
        assert(_elementType);
    }

    public this(SourceLocation location, TypeReferenceNode elementType)
    in
    {
        assert(location);
        assert(elementType);
    }
    body
    {
        super(location);

        _elementType = elementType;
    }

    @property public final TypeReferenceNode elementType()
    {
        return _elementType;
    }

    @property public override ReadOnlyIndexable!Node children()
    {
        return toReadOnlyIndexable!Node(_elementType);
    }
}

public class VectorTypeReferenceNode : TypeReferenceNode
{
    private TypeReferenceNode _elementType;
    private LiteralValueNode _elements;

    invariant()
    {
        assert(_elementType);
        assert(_elements);
    }

    public this(SourceLocation location, TypeReferenceNode elementType, LiteralValueNode elements)
    in
    {
        assert(location);
        assert(elementType);
        assert(elements);
    }
    body
    {
        super(location);

        _elementType = elementType;
        _elements = elements;
    }

    @property public final TypeReferenceNode elementType()
    {
        return _elementType;
    }

    @property public final LiteralValueNode elements()
    {
        return _elements;
    }

    @property public override ReadOnlyIndexable!Node children()
    {
        return toReadOnlyIndexable!Node(_elementType, _elements);
    }
}

public class FunctionPointerTypeReferenceNode : TypeReferenceNode
{
    private CallingConvention _callingConvention;
    private TypeReferenceNode _returnType;
    private NoNullList!TypeReferenceNode _parameterTypes;

    invariant()
    {
        assert(_parameterTypes);
    }

    public this(SourceLocation location, CallingConvention callingConvention, TypeReferenceNode returnType,
                NoNullList!TypeReferenceNode parameterTypes)
    in
    {
        assert(location);
        assert(parameterTypes);
    }
    body
    {
        super(location);

        _callingConvention = callingConvention;
        _returnType = returnType;
        _parameterTypes = parameterTypes.duplicate();
    }

    @property public final CallingConvention callingConvention()
    {
        return _callingConvention;
    }

    @property public final TypeReferenceNode returnType()
    {
        return _returnType;
    }

    @property public final ReadOnlyIndexable!TypeReferenceNode parameterTypes()
    {
        return _parameterTypes;
    }

    @property public override ReadOnlyIndexable!Node children()
    {
        return new List!Node(concat(toReadOnlyIndexable!Node(_returnType), castItems!Node(_parameterTypes)));
    }

    public override string toString()
    {
        return "calling convention: " ~ to!string(_callingConvention);
    }
}

public abstract class CoreTypeReferenceNode : TypeReferenceNode
{
    public this(SourceLocation location)
    in
    {
        assert(location);
    }
    body
    {
        super(location);
    }

    @property public abstract SimpleNameNode name();
}

private mixin template DefineCoreTypeNode(string type, string name)
{
    mixin("public class " ~ type ~ "TypeReferenceNode : CoreTypeReferenceNode" ~
          "{" ~
          "    private SimpleNameNode _name;" ~
          "" ~
          "    invariant()" ~
          "    {" ~
          "        assert(_name);" ~
          "    }" ~
          "" ~
          "    public this(SourceLocation location)" ~
          "    in" ~
          "    {" ~
          "        assert(location);" ~
          "    }" ~
          "    body" ~
          "    {" ~
          "        super(location);" ~
          "" ~
          "        _name = new SimpleNameNode(location, \"" ~ name ~ "\");" ~
          "    }" ~
          "" ~
          "    @property public final override SimpleNameNode name()" ~
          "    {" ~
          "        return _name;" ~
          "    }" ~
          "" ~
          "    @property public override ReadOnlyIndexable!Node children()" ~
          "    {" ~
          "        return toReadOnlyIndexable!Node(_name);" ~
          "    }" ~
          "}");
}

mixin DefineCoreTypeNode!("Int8", "int8");
mixin DefineCoreTypeNode!("UInt8", "uint8");
mixin DefineCoreTypeNode!("Int16", "int16");
mixin DefineCoreTypeNode!("UInt16", "uint16");
mixin DefineCoreTypeNode!("Int32", "int32");
mixin DefineCoreTypeNode!("UInt32", "uint32");
mixin DefineCoreTypeNode!("Int64", "int64");
mixin DefineCoreTypeNode!("UInt64", "uint64");
mixin DefineCoreTypeNode!("NativeInt", "int");
mixin DefineCoreTypeNode!("NativeUInt", "uint");
mixin DefineCoreTypeNode!("Float32", "float32");
mixin DefineCoreTypeNode!("Float64", "float64");

public class FieldReferenceNode : Node
{
    private StructureTypeReferenceNode _typeName;
    private SimpleNameNode _name;

    invariant()
    {
        assert(_typeName);
        assert(_name);
    }

    public this(SourceLocation location, StructureTypeReferenceNode typeName, SimpleNameNode name)
    in
    {
        assert(location);
        assert(typeName);
        assert(name);
    }
    body
    {
        super(location);

        _typeName = typeName;
        _name = name;
    }

    @property public final StructureTypeReferenceNode typeName()
    {
        return _typeName;
    }

    @property public final SimpleNameNode name()
    {
        return _name;
    }

    @property public override ReadOnlyIndexable!Node children()
    {
        return toReadOnlyIndexable!Node(_typeName, _name);
    }
}

public class FunctionReferenceNode : Node
{
    private ModuleReferenceNode _moduleName;
    private SimpleNameNode _name;

    invariant()
    {
        assert(_name);
    }

    public this(SourceLocation location, ModuleReferenceNode moduleName, SimpleNameNode name)
    in
    {
        assert(location);
        assert(name);
    }
    body
    {
        super(location);

        _moduleName = moduleName;
        _name = name;
    }

    @property public final ModuleReferenceNode moduleName()
    {
        return _moduleName;
    }

    @property public final SimpleNameNode name()
    {
        return _name;
    }

    @property public override ReadOnlyIndexable!Node children()
    {
        return toReadOnlyIndexable!Node(_moduleName, _name);
    }
}

public class TypeDeclarationNode : DeclarationNode
{
    private SimpleNameNode _name;
    private LiteralValueNode _alignment;
    private NoNullList!FieldDeclarationNode _fields;

    invariant()
    {
        assert(_name);
        assert(_fields);
    }

    public this(SourceLocation location, SimpleNameNode name, LiteralValueNode alignment, NoNullList!FieldDeclarationNode fields)
    in
    {
        assert(location);
        assert(name);
        assert(fields);
    }
    body
    {
        super(location);

        _name = name;
        _alignment = alignment;
        _fields = fields.duplicate();
    }

    @property public final SimpleNameNode name()
    {
        return _name;
    }

    @property public final LiteralValueNode alignment()
    {
        return _alignment;
    }

    @property public final ReadOnlyIndexable!FieldDeclarationNode fields()
    {
        return _fields;
    }

    @property public override ReadOnlyIndexable!Node children()
    {
        return new List!Node(concat(toReadOnlyIndexable!Node(_name), toReadOnlyIndexable!Node(_alignment), castItems!Node(_fields)));
    }
}

public class FieldDeclarationNode : Node
{
    private TypeReferenceNode _type;
    private SimpleNameNode _name;
    private FieldStorage _storage;

    invariant()
    {
        assert(_type);
        assert(_name);
    }

    public this(SourceLocation location, TypeReferenceNode type, SimpleNameNode name,
                FieldStorage storage)
    in
    {
        assert(location);
        assert(type);
        assert(name);
    }
    body
    {
        super(location);

        _type = type;
        _name = name;
        _storage = storage;
    }

    @property public final TypeReferenceNode type()
    {
        return _type;
    }

    @property public final SimpleNameNode name()
    {
        return _name;
    }

    @property public final FieldStorage storage()
    {
        return _storage;
    }

    @property public override ReadOnlyIndexable!Node children()
    {
        return toReadOnlyIndexable!Node(_type, _name);
    }

    public override string toString()
    {
        return "storage: " ~ to!string(_storage);
    }
}

public class ParameterNode : Node
{
    private TypeReferenceNode _type;

    invariant()
    {
        assert(_type);
    }

    public this(SourceLocation location, TypeReferenceNode type)
    in
    {
        assert(location);
        assert(type);
    }
    body
    {
        super(location);

        _type = type;
    }

    @property public final TypeReferenceNode type()
    {
        return _type;
    }

    @property public override ReadOnlyIndexable!Node children()
    {
        return toReadOnlyIndexable!Node(_type);
    }
}

public class FunctionDeclarationNode : DeclarationNode
{
    private SimpleNameNode _name;
    private CallingConvention _callingConvention;
    private FunctionAttributes _attributes;
    private NoNullList!ParameterNode _parameters;
    private TypeReferenceNode _returnType;
    private NoNullList!RegisterDeclarationNode _registers;
    private NoNullList!BasicBlockDeclarationNode _blocks;

    invariant()
    {
        assert(_name);
        assert(_parameters);
        assert(_registers);
        assert(_blocks);
    }

    public this(SourceLocation location, SimpleNameNode name, CallingConvention callingConvention,
                FunctionAttributes attributes, NoNullList!ParameterNode parameters, TypeReferenceNode returnType,
                NoNullList!RegisterDeclarationNode registers, NoNullList!BasicBlockDeclarationNode blocks)
    in
    {
        assert(location);
        assert(name);
        assert(parameters);
        assert(registers);
        assert(blocks);
    }
    body
    {
        super(location);

        _name = name;
        _callingConvention = callingConvention;
        _attributes = attributes;
        _parameters = parameters.duplicate();
        _returnType = returnType;
        _registers = registers.duplicate();
        _blocks = blocks.duplicate();
    }

    @property public final SimpleNameNode name()
    {
        return _name;
    }

    @property public final CallingConvention callingConvention()
    {
        return _callingConvention;
    }

    @property public final FunctionAttributes attributes()
    {
        return _attributes;
    }

    @property public final ReadOnlyIndexable!ParameterNode parameters()
    {
        return _parameters;
    }

    @property public final TypeReferenceNode returnType()
    {
        return _returnType;
    }

    @property public final ReadOnlyIndexable!RegisterDeclarationNode registers()
    {
        return _registers;
    }

    @property public final ReadOnlyIndexable!BasicBlockDeclarationNode blocks()
    {
        return _blocks;
    }

    @property public override ReadOnlyIndexable!Node children()
    {
        auto params = castItems!Node(_parameters);
        auto regs = castItems!Node(_registers);
        auto blocks = castItems!Node(_blocks);

        return new List!Node(concat(toReadOnlyIndexable!Node(_name), toReadOnlyIndexable!Node(_returnType), params, regs, blocks));
    }

    public override string toString()
    {
        return "calling convention: " ~ to!string(_callingConvention) ~ ", attributes: " ~ to!string(_attributes);
    }
}

public class RegisterDeclarationNode : Node
{
    private SimpleNameNode _name;
    private TypeReferenceNode _type;

    invariant()
    {
        assert(_name);
        assert(_type);
    }

    public this(SourceLocation location, SimpleNameNode name, TypeReferenceNode type)
    in
    {
        assert(location);
        assert(name);
        assert(type);
    }
    body
    {
        super(location);

        _name = name;
        _type = type;
    }

    @property public final SimpleNameNode name()
    {
        return _name;
    }

    @property public final TypeReferenceNode type()
    {
        return _type;
    }

    @property public override ReadOnlyIndexable!Node children()
    {
        return toReadOnlyIndexable!Node(_type, _name);
    }
}

public class BasicBlockDeclarationNode : Node
{
    private SimpleNameNode _name;
    private NoNullList!InstructionNode _instructions;

    invariant()
    {
        assert(_name);
        assert(_instructions);
    }

    public this(SourceLocation location, SimpleNameNode name, NoNullList!InstructionNode instructions)
    in
    {
        assert(location);
        assert(name);
        assert(instructions);
    }
    body
    {
        super(location);

        _name = name;
        _instructions = instructions.duplicate();
    }

    @property public final SimpleNameNode name()
    {
        return _name;
    }

    @property public final ReadOnlyIndexable!InstructionNode instructions()
    {
        return _instructions;
    }

    @property public override ReadOnlyIndexable!Node children()
    {
        return new List!Node(concat(toReadOnlyIndexable!Node(_name), castItems!Node(_instructions)));
    }
}

public class RegisterReferenceNode : Node
{
    private SimpleNameNode _name;

    invariant()
    {
        assert(_name);
    }

    public this(SourceLocation location, SimpleNameNode name)
    in
    {
        assert(location);
        assert(name);
    }
    body
    {
        super(location);

        _name = name;
    }

    @property public final SimpleNameNode name()
    {
        return _name;
    }

    @property public override ReadOnlyIndexable!Node children()
    {
        return toReadOnlyIndexable!Node(_name);
    }
}

public class BasicBlockReferenceNode : Node
{
    private SimpleNameNode _name;

    invariant()
    {
        assert(_name);
    }

    public this(SourceLocation location, SimpleNameNode name)
    in
    {
        assert(location);
        assert(name);
    }
    body
    {
        super(location);

        _name = name;
    }

    @property public final SimpleNameNode name()
    {
        return _name;
    }

    @property public override ReadOnlyIndexable!Node children()
    {
        return toReadOnlyIndexable!Node(_name);
    }
}

public class BranchSelectorNode : Node
{
    private BasicBlockReferenceNode _trueBlock;
    private BasicBlockReferenceNode _falseBlock;

    invariant()
    {
        assert(_trueBlock);
        assert(_falseBlock);
    }

    public this(SourceLocation location, BasicBlockReferenceNode trueBlock, BasicBlockReferenceNode falseBlock)
    in
    {
        assert(location);
        assert(trueBlock);
        assert(falseBlock);
    }
    body
    {
        super(location);

        _trueBlock = trueBlock;
        _falseBlock = falseBlock;
    }

    @property public final BasicBlockReferenceNode trueBlock()
    {
        return _trueBlock;
    }

    @property public final BasicBlockReferenceNode falseBlock()
    {
        return _falseBlock;
    }

    @property public override ReadOnlyIndexable!Node children()
    {
        return toReadOnlyIndexable!Node(_trueBlock, _falseBlock);
    }
}

public class RegisterSelectorNode : Node
{
    private NoNullList!RegisterReferenceNode _registers;

    invariant()
    {
        assert(_registers);
    }

    public this(SourceLocation location, NoNullList!RegisterReferenceNode registers)
    in
    {
        assert(location);
        assert(registers);
    }
    body
    {
        super(location);

        _registers = registers.duplicate();
    }

    @property public final ReadOnlyIndexable!RegisterReferenceNode registers()
    {
        return _registers;
    }

    @property public override ReadOnlyIndexable!Node children()
    {
        return new List!Node(castItems!Node(_registers));
    }
}

public class LiteralValueNode : Node
{
    private string _value;

    invariant()
    {
        assert(_value);
    }

    public this(SourceLocation location, string value)
    in
    {
        assert(location);
        assert(value);
    }
    body
    {
        super(location);

        _value = value;
    }

    @property public final string value()
    {
        return _value;
    }

    public override string toString()
    {
        return "value: " ~ value;
    }
}

public class ArrayLiteralNode : Node
{
    private NoNullList!LiteralValueNode _values;

    invariant()
    {
        assert(_values);
    }

    public this(SourceLocation location, NoNullList!LiteralValueNode values)
    in
    {
        assert(location);
        assert(values);
    }
    body
    {
        super(location);

        _values = values.duplicate();
    }

    @property public final ReadOnlyIndexable!LiteralValueNode values()
    {
        return _values;
    }

    @property public override ReadOnlyIndexable!Node children()
    {
        return new List!Node(castItems!Node(_values));
    }
}

public class FFISignatureNode : Node
{
    private SimpleNameNode _library;
    private SimpleNameNode _entryPoint;

    invariant()
    {
        assert(_library);
        assert(_entryPoint);
    }

    public this(SourceLocation location, SimpleNameNode library, SimpleNameNode entryPoint)
    in
    {
        assert(location);
        assert(library);
        assert(entryPoint);
    }
    body
    {
        super(location);

        _library = library;
        _entryPoint = entryPoint;
    }

    @property public final SimpleNameNode library()
    out (result)
    {
        assert(result);
    }
    body
    {
        return _library;
    }

    @property public final SimpleNameNode entryPoint()
    out (result)
    {
        assert(result);
    }
    body
    {
        return _entryPoint;
    }

    @property public override ReadOnlyIndexable!Node children()
    {
        return toReadOnlyIndexable!Node(_library, _entryPoint);
    }
}

alias Algebraic!(LiteralValueNode,
                 ArrayLiteralNode,
                 TypeReferenceNode,
                 FieldReferenceNode,
                 FunctionReferenceNode,
                 BasicBlockReferenceNode,
                 BranchSelectorNode,
                 RegisterSelectorNode,
                 FFISignatureNode) InstructionOperand;

public class InstructionOperandNode : Node
{
    private InstructionOperand _operand;

    invariant()
    {
        assert(_operand.hasValue);
    }

    public this(SourceLocation location, InstructionOperand operand)
    in
    {
        assert(location);
        assert(operand.hasValue);
    }
    body
    {
        super(location);

        _operand = operand;
    }

    @property public final InstructionOperand operand()
    {
        return _operand;
    }

    @property public override ReadOnlyIndexable!Node children()
    {
        return toReadOnlyIndexable!Node(_operand.coerce!Node());
    }
}

public class InstructionNode : Node
{
    private OpCode _opCode;
    private RegisterReferenceNode _target;
    private RegisterReferenceNode _source1;
    private RegisterReferenceNode _source2;
    private RegisterReferenceNode _source3;
    private InstructionOperandNode _operand;

    invariant()
    {
        assert(_opCode);
    }

    public this(SourceLocation location, OpCode opCode, RegisterReferenceNode target,
                RegisterReferenceNode source1, RegisterReferenceNode source2, RegisterReferenceNode source3,
                InstructionOperandNode operand)
    in
    {
        assert(location);
        assert(opCode);
    }
    body
    {
        super(location);

        _opCode = opCode;
        _target = target;
        _source1 = source1;
        _source2 = source2;
        _source3 = source3;
        _operand = operand;
    }

    @property public final OpCode opCode()
    {
        return _opCode;
    }

    @property public final RegisterReferenceNode target()
    {
        return _target;
    }

    @property public final RegisterReferenceNode source1()
    {
        return _source1;
    }

    @property public final RegisterReferenceNode source2()
    {
        return _source2;
    }

    @property public final RegisterReferenceNode source3()
    {
        return _source3;
    }

    @property public final InstructionOperandNode operand()
    {
        return _operand;
    }

    @property public override ReadOnlyIndexable!Node children()
    {
        return toReadOnlyIndexable!Node(target, source1, source2, source3, operand);
    }

    public override string toString()
    {
        return "opcode: " ~ _opCode.name ~ "/" ~ to!string(_opCode.code);
    }
}