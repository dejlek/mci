module mci.core.config;

import mci.core.common;

// This file figures out what kind of environment we're running
// in and sets appropriate constants. Reliance on these constants
// should be avoided if possible.

version (MCI_Ddoc)
{
    public enum Compiler compiler = Compiler.init; /// Indicates what compiler the MCI is being built with.
    public enum string compilerName = string.init; /// Holds the name of the compiler the MCI is being built with.
}
else version (DigitalMars)
{
    public enum Compiler compiler = Compiler.dmd;
    public enum string compilerName = "DMD";
}
else version (GNU)
{
    public enum Compiler compiler = Compiler.gdc;
    public enum string compilerName = "GDC";
}
else version (LDC)
{
    public enum Compiler compiler = Compiler.ldc;
    public enum string compilerName = "LDC";
}
else
    static assert(false, "Unknown or unsupported compiler.");

version (D_Version2)
{
}
else
    static assert(false, "Unknown or unsupported D language version.");

version (MCI_Ddoc)
{
    public enum InlineAssembly inlineAssembly = InlineAssembly.init; /// Indicates what kind of inline assembly the compiler provides.
}
else version (D_InlineAsm_X86_64)
{
    public enum InlineAssembly inlineAssembly = InlineAssembly.dmd64;
}
else version (D_InlineAsm_X86)
{
    public enum InlineAssembly inlineAssembly = InlineAssembly.dmd32;
}
else version (GNU)
{
    public enum InlineAssembly inlineAssembly = InlineAssembly.gnu;
}
else version (LDC)
{
    public enum InlineAssembly inlineAssembly = InlineAssembly.llvm;
}
else
    static assert(false, "Inline assembly not available.");

version (MCI_Ddoc)
{
    public enum Architecture architecture = Architecture.init; /// Indicates the architecture the MCI is being built for.
    public enum string architectureName = string.init; /// Holds the name of the architecture the MCI is being built for.
}
else version (X86)
{
    public enum Architecture architecture = Architecture.x86;
    public enum string architectureName = "x86";
}
else version (X86_64)
{
    public enum Architecture architecture = Architecture.x86;
    public enum string architectureName = "x86";
}
else version (ARM)
{
    public enum Architecture architecture = Architecture.arm;
    public enum string architectureName = "ARM";
}
else version (PPC)
{
    public enum Architecture architecture = Architecture.ppc;
    public enum string architectureName = "PowerPC";
}
else version (PPC64)
{
    public enum Architecture architecture = Architecture.ppc;
    public enum string architectureName = "PowerPC";
}
else version (IA64)
{
    public enum Architecture architecture = Architecture.ia64;
    public enum string architectureName = "Itanium";
}
else version (MIPS)
{
    public enum Architecture architecture = Architecture.mips;
    public enum string architectureName = "MIPS";
}
else version (MIPS64)
{
    public enum Architecture architecture = Architecture.mips;
    public enum string architectureName = "MIPS";
}
else
    static assert(false, "Unknown or unsupported processor architecture.");

version (MCI_Ddoc)
    public enum bool is32Bit = bool.init; /// Indicates what bitness the MCI is being built for.
else version (D_LP64)
    public enum bool is32Bit = false;
else
    public enum bool is32Bit = true;

version (MCI_Ddoc)
{
    public enum Endianness endianness = Endianness.init; /// Indicates what endianness the MCI is being built for.
    public string endiannessName = string.init; /// Holds the name of the endianness the MCI is being built for.
}
else version (LittleEndian)
{
    public enum Endianness endianness = Endianness.littleEndian;
    public string endiannessName = "Little Endian (LE)";
}
else version (BigEndian)
{
    public enum Endianness endianness = Endianness.bigEndian;
    public string endiannessName = "Big Endian (BE)";
}
else
    static assert(false, "Endianness could not be determined.");

version (MCI_Ddoc)
{
    public enum OperatingSystem operatingSystem = OperatingSystem.init; /// Indicates what operating system MCI is being built for.
    public enum string operatingSystemName = string.init; /// Holds the name of the operating system the MCI is being built for.

    public enum bool isPOSIX = bool.init; /// Indicates whether the operating system the MCI is being built for is POSIX-compliant.
    public enum bool isWindows = bool.init; /// Indicates whether the operating system the MCI is being built for is Windows.
}
else version (Windows)
{
    public enum OperatingSystem operatingSystem = OperatingSystem.windows;
    public enum string operatingSystemName = "Windows";

    public enum bool isPOSIX = false;
    public enum bool isWindows = true;
}
else version (Posix)
{
    version (FreeBSD)
    {
        public enum OperatingSystem operatingSystem = OperatingSystem.freebsd;
        public enum string operatingSystemName = "FreeBSD";
    }
    else version (AIX)
    {
        public enum OperatingSystem operatingSystem = OperatingSystem.aix;
        public enum string operatingSystemName = "AIX";
    }
    else version (Solaris)
    {
        public enum OperatingSystem operatingSystem = OperatingSystem.solaris;
        public enum string operatingSystemName = "Solaris";
    }
    else version (linux)
    {
        public enum OperatingSystem operatingSystem = OperatingSystem.linux;
        public enum string operatingSystemName = "Linux";
    }
    else version (OSX)
    {
        public enum OperatingSystem operatingSystem = OperatingSystem.osx;
        public enum string operatingSystemName = "OS X";
    }
    else
        static assert(false, "Unknown or unsupported POSIX operating system.");

    public enum bool isPOSIX = true;
    public enum bool isWindows = false;
}
else
    static assert(false, "Unknown or unsupported operating system.");

version (MCI_Ddoc)
{
    public enum EmulationLayer emulationLayer = EmulationLayer.init; /// Indicates what emulation layer, if any, the MCI is being built under.
    public enum string emulationLayerName = string.init; /// Holds the name of the emulation layer the MCI is being built under.
}
else version (Cygwin)
{
    public enum EmulationLayer emulationLayer = EmulationLayer.cygwin;
    public enum string emulationLayerName = "Cygwin";
}
else version (MinGW)
{
    public enum EmulationLayer emulationLayer = EmulationLayer.mingw;
    public enum string emulationLayerName = "MinGW";
}
else
{
    public enum EmulationLayer emulationLayer = EmulationLayer.none;
    public enum string emulationLayerName = "None";
}

version (MCI_Ddoc)
{
    public enum FloatingPointMethod floatingPointMethod = FloatingPointMethod.init; /// Indicates which method is used to execute floating-point operations.
    public enum string floatingPointMethodName = string.init; /// Holds the name of the method used to execute floating-point operations.
}
else version (D_HardFloat)
{
    public enum FloatingPointMethod floatingPointMethod = FloatingPointMethod.hard;
    public enum string floatingPointMethodName = "HardFloat";
}
else
{
    public enum FloatingPointMethod floatingPointMethod = FloatingPointMethod.soft;
    public enum string floatingPointMethodName = "SoftFloat";
}
