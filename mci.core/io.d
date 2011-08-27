module mci.core.io;

import std.stdio;

public class BinaryReader
{
    private File _file;
    
    public this(File file)
    {
        _file = file;
    }
    
    private mixin template Read(string name, string type)
    {
        mixin("public final " ~ type ~ " read" ~ name ~ "()" ~
              "{" ~
              "    " ~ type ~ "[1] arr;" ~
              "    _file.rawRead(arr);" ~
              "    return arr[0];" ~
              "}");
    }
    
    mixin Read!("Boolean", "bool");
    mixin Read!("Int8", "byte");
    mixin Read!("UInt8", "ubyte");
    mixin Read!("Int16", "short");
    mixin Read!("UInt16", "ushort");
    mixin Read!("Int32", "int");
    mixin Read!("UInt32", "uint");
    mixin Read!("Int64", "long");
    mixin Read!("UInt64", "ulong");
    mixin Read!("NativeInt", "size_t");
    mixin Read!("Float32", "float");
    mixin Read!("Float64", "double");
    mixin Read!("NativeFloat", "real");
    mixin Read!("Char", "char");
    mixin Read!("WChar", "wchar");
    mixin Read!("DChar", "dchar");
    
    private mixin template ReadArray(string name, string type, string read)
    {
        mixin("public final " ~ type ~ " read" ~ name ~ "(size_t length)" ~
              "{" ~
              "    " ~ type ~ " arr;" ~
              "" ~
              "    for (size_t i = 0; i < length; i++)" ~
              "        arr ~= read" ~ read ~ "();" ~
              "" ~
              "    return arr;" ~
              "}");
    }
    
    mixin ReadArray!("Bytes", "ubyte[]", "UInt8");
    mixin ReadArray!("String", "string", "Char");
    mixin ReadArray!("WString", "wstring", "WChar");
    mixin ReadArray!("DString", "dstring", "DChar");
}

public class BinaryWriter
{
    private File _file;
    
    public this(File file)
    {
        _file = file;
    }
    
    private mixin template Write(string name, string type)
    {
        mixin("public final void write" ~ name ~ "(" ~ type ~ " value)" ~
              "{" ~
                  "auto arr = [value];" ~
                  "_file.rawWrite(arr);" ~
              "}");
    }
    
    mixin Write!("Boolean", "bool");
    mixin Write!("Int8", "byte");
    mixin Write!("UInt8", "ubyte");
    mixin Write!("Int16", "short");
    mixin Write!("UInt16", "ushort");
    mixin Write!("Int32", "int");
    mixin Write!("UInt32", "uint");
    mixin Write!("Int64", "long");
    mixin Write!("UInt64", "ulong");
    mixin Write!("NativeInt", "size_t");
    mixin Write!("Float32", "float");
    mixin Write!("Float64", "double");
    mixin Write!("NativeFloat", "real");
    mixin Write!("Char", "char");
    mixin Write!("WChar", "wchar");
    mixin Write!("DChar", "dchar");
    
    private mixin template WriteArray(string name, string type, string read)
    {
        mixin("public final void write" ~ name ~ "(" ~ type ~ " array)" ~
              "{" ~
              "    foreach (item; array)" ~
              "        write" ~ read ~ "(item);" ~
              "}");
    }
    
    mixin WriteArray!("Bytes", "ubyte[]", "UInt8");
    mixin WriteArray!("String", "string", "Char");
    mixin WriteArray!("WString", "wstring", "WChar");
    mixin WriteArray!("DString", "dstring", "DChar");
}
