module mci.vm.memory.info;

import mci.core.common,
       mci.core.container,
       mci.core.nullable,
       mci.core.tuple,
       mci.core.analysis.utilities,
       mci.core.typing.core,
       mci.core.typing.types,
       mci.vm.memory.layout;

public final class RuntimeTypeInfo
{
    private Type _type;
    private size_t _size;
    private BitArray _bitmap;

    invariant()
    {
        assert(_type);
        assert(isManaged(cast()_type));
        assert(tryCast!StructureType(_type) ? !!_bitmap : !_bitmap);
    }

    private this(Type type, size_t size, BitArray bitmap)
    in
    {
        assert(type);
        assert(isManaged(type));
        assert(tryCast!StructureType(type) ? !!bitmap : !bitmap);
    }
    body
    {
        _type = type;
        _size = size;
        _bitmap = bitmap;
    }

    @property public Type type()
    out (result)
    {
        assert(result);
        assert(isManaged(cast()result));
    }
    body
    {
        return _type;
    }

    @property public size_t size()
    {
        return _size;
    }

    @property public ReadOnlyIndexable!bool bitmap()
    out (result)
    {
        assert(tryCast!StructureType(_type) ? !!result : !result);
    }
    body
    {
        return _bitmap;
    }
}

private __gshared NoNullDictionary!(Tuple!(Type, bool), RuntimeTypeInfo, false) typeInfoCache;

shared static this()
{
    typeInfoCache = new typeof(typeInfoCache)();
}

private size_t computeRealSize(Type type, bool is32Bit)
in
{
    assert(type);
    assert(isManaged(type));
}
body
{
    if (auto r = cast(ReferenceType)type)
        return computeSize(r.elementType, is32Bit);
    else if (auto v = cast(VectorType)type)
        return computeSize(v.elementType, is32Bit) * v.elements;
    else // For arrays, we just compute the size of the length field.
        return computeSize(NativeUIntType.instance, is32Bit);
}

public RuntimeTypeInfo getTypeInfo(Type type, bool is32Bit)
in
{
    assert(type);
    assert(isManaged(type));
}
body
{
    synchronized (typeInfoCache)
    {
        auto tup = tuple(type, is32Bit);

        if (auto info = tup in typeInfoCache)
            return *info;

        BitArray bitmap;

        if (auto structType = tryCast!StructureType(type))
            bitmap = computeBitmap(structType, is32Bit);

        return typeInfoCache[tup] = new RuntimeTypeInfo(type, computeRealSize(type, is32Bit), bitmap);
    }
}
