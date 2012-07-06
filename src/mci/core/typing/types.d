module mci.core.typing.types;

import std.conv,
       mci.core.container,
       mci.core.math,
       mci.core.nullable,
       mci.core.analysis.utilities,
       mci.core.code.metadata,
       mci.core.code.modules,
       mci.core.code.functions,
       mci.core.typing.members,
       mci.core.utilities;

public abstract class Type
{
    package this() pure nothrow
    {
    }

    @property public abstract string name();

    public override string toString()
    {
        return name;
    }
}

public final class StructureType : Type
{
    private Module _module;
    private string _name;
    private uint _alignment;
    private NoNullDictionary!(string, Field) _fields;
    private bool _isClosed;
    private List!MetadataPair _metadata;

    invariant()
    {
        assert(_module);
        assert(_name);
        assert(!_alignment || powerOfTwo(_alignment));
        assert(_fields);
        assert(_metadata);
    }

    public this(Module module_, string name, uint alignment = 0)
    in
    {
        assert(module_);
        assert(name);
        assert(!alignment || powerOfTwo(alignment));
        assert(!module_.types.get(name));
    }
    body
    {
        _module = module_;
        _name = name;
        _alignment = alignment;
        _fields = new typeof(_fields)();
        _metadata = new typeof(_metadata)();

        (cast(NoNullDictionary!(string, StructureType))module_.types)[name] = this;
    }

    @property public uint alignment() pure nothrow
    {
        return _alignment;
    }

    @property public Module module_() pure nothrow
    out (result)
    {
        assert(result);
    }
    body
    {
        return _module;
    }

    @property public Lookup!(string, Field) fields() pure nothrow
    in
    {
        assert(_isClosed);
    }
    out (result)
    {
        assert(result);
    }
    body
    {
        return _fields;
    }

    @property public bool isClosed() pure nothrow
    {
        return _isClosed;
    }

    @property public List!MetadataPair metadata() pure nothrow
    out (result)
    {
        assert(result);
    }
    body
    {
        return _metadata;
    }

    @property public override string name()
    {
        return _name;
    }

    public override string toString()
    {
        return _module.toString() ~ "/" ~ escapeIdentifier(_name);
    }

    public Field createField(string name, Type type, FieldStorage storage = FieldStorage.instance)
    in
    {
        assert(name);
        assert(type);
        assert(name !in _fields);

        if (storage == FieldStorage.instance)
            if (auto struc = cast(StructureType)type)
                assert(!hasCycle(struc));

        assert(!_isClosed);
    }
    out (result)
    {
        assert(result);
    }
    body
    {
        return _fields[name] = new Field(this, name, type, storage);
    }

    public void close() pure nothrow
    in
    {
        assert(!_isClosed);
    }
    body
    {
        _isClosed = true;
    }

    public bool hasCycle(StructureType fieldType)
    in
    {
        assert(fieldType);
    }
    body
    {
        if (fieldType is this)
            return true;

        // Important that we iterate _fields and not fields.
        foreach (field; fieldType._fields)
            if (auto struc = cast(StructureType)field.y.type)
                if (hasCycle(struc))
                    return true;

        return false;
    }
}

public final class PointerType : Type
{
    private Type _elementType;

    invariant()
    {
        assert(_elementType);
    }

    package this(Type elementType)
    in
    {
        assert(elementType);
    }
    body
    {
        _elementType = elementType;
    }

    @property public Type elementType() pure nothrow
    out (result)
    {
        assert(result);
    }
    body
    {
        return _elementType;
    }

    @property public override string name()
    {
        return elementType.toString() ~ "*";
    }
}

public final class ReferenceType : Type
{
    private StructureType _elementType;

    invariant()
    {
        assert(_elementType);
    }

    package this(StructureType elementType)
    in
    {
        assert(elementType);
    }
    body
    {
        _elementType = elementType;
    }

    @property public StructureType elementType() pure nothrow
    out (result)
    {
        assert(result);
    }
    body
    {
        return _elementType;
    }

    @property public override string name()
    {
        return elementType.toString() ~ "&";
    }
}

public final class FunctionPointerType : Type
{
    private CallingConvention _callingConvention;
    private Type _returnType;
    private NoNullList!Type _parameterTypes;

    invariant()
    {
        assert(_parameterTypes);
    }

    package this(CallingConvention callingConvention, Type returnType, NoNullList!Type parameterTypes)
    in
    {
        assert(parameterTypes);
    }
    body
    {
        _callingConvention = callingConvention;
        _returnType = returnType;
        _parameterTypes = parameterTypes.duplicate();
    }

    @property public CallingConvention callingConvention() pure nothrow
    {
        return _callingConvention;
    }

    @property public Type returnType() pure nothrow
    {
        return _returnType;
    }

    @property public ReadOnlyIndexable!Type parameterTypes() pure nothrow
    out (result)
    {
        assert(result);
    }
    body
    {
        return _parameterTypes;
    }

    @property public override string name()
    {
        string s;

        s ~= (_returnType ? _returnType.toString() : "void") ~ "(";

        foreach (i, param; _parameterTypes)
        {
            s ~= param.toString();

            if (i < _parameterTypes.count - 1)
                s ~= ", ";
        }

        s ~= ")";

        final switch (_callingConvention)
        {
            case CallingConvention.standard:
                break;
            case CallingConvention.cdecl:
                s ~= " cdecl";
                break;
            case CallingConvention.stdCall:
                s ~= " stdcall";
                break;
        }

        return s;
    }
}

public final class ArrayType : Type
{
    private Type _elementType;

    invariant()
    {
        assert(_elementType);
    }

    package this(Type elementType)
    in
    {
        assert(elementType);
    }
    body
    {
        _elementType = elementType;
    }

    @property public Type elementType() pure nothrow
    out (result)
    {
        assert(result);
    }
    body
    {
        return _elementType;
    }

    @property public override string name()
    {
        return elementType.toString() ~ "[]";
    }
}

public final class VectorType : Type
{
    private Type _elementType;
    private uint _elements;

    invariant()
    {
        assert(_elementType);
    }

    package this(Type elementType, uint elements)
    in
    {
        assert(elementType);
    }
    body
    {
        _elementType = elementType;
        _elements = elements;
    }

    @property public Type elementType() pure nothrow
    out (result)
    {
        assert(result);
    }
    body
    {
        return _elementType;
    }

    @property public uint elements() pure nothrow
    {
        return _elements;
    }

    @property public override string name()
    {
        return elementType.toString() ~ "[" ~ to!string(_elements) ~ "]";
    }
}
