#Requires -Version 5.1

<#
.SYNOPSIS
    Tanium sensor that reports whether each listed file is a 32-bit or 64-bit PE image.

.DESCRIPTION
    Takes a comma-separated list of file paths from the Tanium sensor parameter
    ||strFiles|| (URL-decoded with [System.Uri]::UnescapeDataString). For each path
    that exists, the internal Get-PEInfo function opens the file read-only, reads the
    DOS header and the optional header magic number, and the script writes one line:

        <Path>|32-bit
        <Path>|64-bit
        <Path>|Not a valid PE file!

    ROM images and unknown magic numbers produce a "ROM File, not supported!" or
    "Unknown PE file type" message instead. A path that does not exist is reported as
    "<Path>|File not found!". A path that exists but cannot be opened (access denied or
    locked by another process) is reported as "<Path>|Unreadable: <reason>". When the
    script runs in a 32-bit process, a requested \System32\ path is redirected to
    \Sysnative\ so the 64-bit file is read. Read-only.

.EXAMPLE
    .\GetBinaryTypeTaniumSensor.ps1

    Run outside Tanium, ||strFiles|| is not replaced, so no real file is checked.
    Use this only to confirm the script loads.

.EXAMPLE
    # In Tanium, set strFiles to: C:\Windows\System32\notepad.exe,C:\Tools\app.exe

    Returns one "<Path>|<Architecture>" line per file.

.NOTES
    Written as a Tanium sensor: the Tanium Client must substitute the ||strFiles||
    parameter. Requires PowerShell 5.1 or later (uses enum definitions). Needs read
    access to the files; no admin rights needed otherwise.
    Imported from jesse-slaton/powershell-utilities at 00676387f42413dc85c8b373791a0364358f6820, from Scripts/General/GetBinaryTypeTaniumSensor.ps1.
#>


function Get-PEInfo {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$filename
    )

    [Uint16]$IMAGE_DOS_SIGNATURE = 0x5A4D
    [Uint16]$IMAGE_NT_OPTIONAL_HDR32_MAGIC = 0x10b
    [UInt16]$IMAGE_NT_OPTIONAL_HDR64_MAGIC = 0x20b
    [UInt16]$IMAGE_ROM_OPTIONAL_HDR_MAGIC = 0x107
    [Uint16]$IMAGE_NUMBEROF_DIRECTORY_ENTRIES = 16
    [Uint16]$IMAGE_SIZEOF_SHORT_NAME = 8
    [Uint16]$IMAGE_SIZEOF_SECTION_HEADER = 40
 
    enum IMAGE_FILE_MACHINE {
        IMAGE_FILE_RELOCS_STRIPPED = 0x0001  # Relocation info stripped from file.
        IMAGE_FILE_EXECUTABLE_IMAGE = 0x0002  # File is executable  (i.e. no unresolved external references).
        IMAGE_FILE_LINE_NUMS_STRIPPED = 0x0004  # Line nunbers stripped from file.
        IMAGE_FILE_LOCAL_SYMS_STRIPPED = 0x0008  # Local symbols stripped from file.
        IMAGE_FILE_AGGRESIVE_WS_TRIM = 0x0010  # Aggressively trim working set
        IMAGE_FILE_LARGE_ADDRESS_AWARE = 0x0020  # App can handle >2gb addresses
        IMAGE_FILE_BYTES_REVERSED_LO = 0x0080  # Bytes of machine word are reversed.
        IMAGE_FILE_32BIT_MACHINE = 0x0100  # 32 bit word machine.
        IMAGE_FILE_DEBUG_STRIPPED = 0x0200  # Debugging info stripped from file in .DBG file
        IMAGE_FILE_REMOVABLE_RUN_FROM_SWAP = 0x0400  # If Image is on removable media, copy and run from the swap file.
        IMAGE_FILE_NET_RUN_FROM_SWAP = 0x0800  # If Image is on Net, copy and run from the swap file.
        IMAGE_FILE_SYSTEM = 0x1000  # System File.
        IMAGE_FILE_DLL = 0x2000  # File is a DLL.
        IMAGE_FILE_UP_SYSTEM_ONLY = 0x4000  # File should only be run on a UP machine
        IMAGE_FILE_BYTES_REVERSED_HI = 0x8000  # Bytes of machine word are reversed.
        IMAGE_FILE_MACHINE_UNKNOWN = 0x0
        IMAGE_FILE_MACHINE_TARGET_HOST = 0x0001  # Useful for indicating we want to interact with the host and not a WoW guest.
        IMAGE_FILE_MACHINE_I386 = 0x014c  # Intel 386.
        IMAGE_FILE_MACHINE_R3000 = 0x0162  # MIPS little-endian, = 0x160 big-endian
        IMAGE_FILE_MACHINE_R4000 = 0x0166  # MIPS little-endian
        IMAGE_FILE_MACHINE_R10000 = 0x0168  # MIPS little-endian
        IMAGE_FILE_MACHINE_WCEMIPSV2 = 0x0169  # MIPS little-endian WCE v2
        IMAGE_FILE_MACHINE_ALPHA = 0x0184  # Alpha_AXP
        IMAGE_FILE_MACHINE_SH3 = 0x01a2  # SH3 little-endian
        IMAGE_FILE_MACHINE_SH3DSP = 0x01a3
        IMAGE_FILE_MACHINE_SH3E = 0x01a4  # SH3E little-endian
        IMAGE_FILE_MACHINE_SH4 = 0x01a6  # SH4 little-endian
        IMAGE_FILE_MACHINE_SH5 = 0x01a8  # SH5
        IMAGE_FILE_MACHINE_ARM = 0x01c0  # ARM Little-Endian
        IMAGE_FILE_MACHINE_THUMB = 0x01c2  # ARM Thumb/Thumb-2 Little-Endian
        IMAGE_FILE_MACHINE_ARMNT = 0x01c4  # ARM Thumb-2 Little-Endian
        IMAGE_FILE_MACHINE_AM33 = 0x01d3
        IMAGE_FILE_MACHINE_POWERPC = 0x01F0  # IBM PowerPC Little-Endian
        IMAGE_FILE_MACHINE_POWERPCFP = 0x01f1
        IMAGE_FILE_MACHINE_IA64 = 0x0200  # Intel 64
        IMAGE_FILE_MACHINE_MIPS16 = 0x0266  # MIPS
        IMAGE_FILE_MACHINE_ALPHA64 = 0x0284  # ALPHA64
        IMAGE_FILE_MACHINE_MIPSFPU = 0x0366  # MIPS
        IMAGE_FILE_MACHINE_MIPSFPU16 = 0x0466  # MIPS
        IMAGE_FILE_MACHINE_AXP64 = 0x0284  # IMAGE_FILE_MACHINE_ALPHA64
        IMAGE_FILE_MACHINE_TRICORE = 0x0520  # Infineon
        IMAGE_FILE_MACHINE_CEF = 0x0CEF
        IMAGE_FILE_MACHINE_EBC = 0x0EBC  # EFI Byte Code
        IMAGE_FILE_MACHINE_AMD64 = 0x8664  # AMD64 (K8)
        IMAGE_FILE_MACHINE_M32R = 0x9041  # M32R little-endian
        IMAGE_FILE_MACHINE_ARM64 = 0xAA64  # ARM64 Little-Endian
        IMAGE_FILE_MACHINE_CEE = 0xC0EE
    }
 
    [Flags()] enum IMAGE_SUBSYSTEM {
        IMAGE_SUBSYSTEM_UNKNOWN = 0   # Unknown subsystem.
        IMAGE_SUBSYSTEM_NATIVE = 1   # Image doesnt require a subsystem.
        IMAGE_SUBSYSTEM_WINDOWS_GUI = 2   # Image runs in the Windows GUI subsystem.
        IMAGE_SUBSYSTEM_WINDOWS_CUI = 3   # Image runs in the Windows character subsystem.
        IMAGE_SUBSYSTEM_OS2_CUI = 5   # image runs in the OS/2 character subsystem.
        IMAGE_SUBSYSTEM_POSIX_CUI = 7   # image runs in the Posix character subsystem.
        IMAGE_SUBSYSTEM_NATIVE_WINDOWS = 8   # image is a native Win9x driver.
        IMAGE_SUBSYSTEM_WINDOWS_CE_GUI = 9   # Image runs in the Windows CE subsystem.
        IMAGE_SUBSYSTEM_EFI_APPLICATION = 10  #
        IMAGE_SUBSYSTEM_EFI_BOOT_SERVICE_DRIVER = 11   #
        IMAGE_SUBSYSTEM_EFI_RUNTIME_DRIVER = 12  #
        IMAGE_SUBSYSTEM_EFI_ROM = 13
        IMAGE_SUBSYSTEM_XBOX = 14
        IMAGE_SUBSYSTEM_WINDOWS_BOOT_APPLICATION = 16
        IMAGE_SUBSYSTEM_XBOX_CODE_CATALOG = 17
    }
 
    [Flags()] enum IMAGE_DLLCHARACTERISTICS {
        IMAGE_DLLCHARACTERISTICS_HIGH_ENTROPY_VA = 0x0020  # Image can handle a high entropy 64-bit virtual address space.
        IMAGE_DLLCHARACTERISTICS_DYNAMIC_BASE = 0x0040     # DLL can move.
        IMAGE_DLLCHARACTERISTICS_FORCE_INTEGRITY = 0x0080     # Code Integrity Image
        IMAGE_DLLCHARACTERISTICS_NX_COMPAT = 0x0100     # Image is NX compatible
        IMAGE_DLLCHARACTERISTICS_NO_ISOLATION = 0x0200     # Image understands isolation and doesn't want it
        IMAGE_DLLCHARACTERISTICS_NO_SEH = 0x0400     # Image does not use SEH.  No SE handler may reside in this image
        IMAGE_DLLCHARACTERISTICS_NO_BIND = 0x0800     # Do not bind this image.
        IMAGE_DLLCHARACTERISTICS_APPCONTAINER = 0x1000     # Image should execute in an AppContainer
        IMAGE_DLLCHARACTERISTICS_WDM_DRIVER = 0x2000     # Driver uses WDM model
        IMAGE_DLLCHARACTERISTICS_GUARD_CF = 0x4000     # Image supports Control Flow Guard.
        IMAGE_DLLCHARACTERISTICS_TERMINAL_SERVER_AWARE = 0x8000
    }
 
    enum IMAGE_DIRECTORY_ENTRY {
        IMAGE_DIRECTORY_ENTRY_EXPORT = 0   # Export Directory
        IMAGE_DIRECTORY_ENTRY_IMPORT = 1   # Import Directory
        IMAGE_DIRECTORY_ENTRY_RESOURCE = 2   # Resource Directory
        IMAGE_DIRECTORY_ENTRY_EXCEPTION = 3   # Exception Directory
        IMAGE_DIRECTORY_ENTRY_SECURITY = 4   # Security Directory
        IMAGE_DIRECTORY_ENTRY_BASERELOC = 5   # Base Relocation Table
        IMAGE_DIRECTORY_ENTRY_DEBUG = 6   # Debug Directory
        #     IMAGE_DIRECTORY_ENTRY_COPYRIGHT = 7   # (X86 usage)
        IMAGE_DIRECTORY_ENTRY_ARCHITECTURE = 7   # Architecture Specific Data
        IMAGE_DIRECTORY_ENTRY_GLOBALPTR = 8   # RVA of GP
        IMAGE_DIRECTORY_ENTRY_TLS = 9   # TLS Directory
        IMAGE_DIRECTORY_ENTRY_LOAD_CONFIG = 10   # Load Configuration Directory
        IMAGE_DIRECTORY_ENTRY_BOUND_IMPORT = 11   # Bound Import Directory in headers
        IMAGE_DIRECTORY_ENTRY_IAT = 12   # Import Address Table
        IMAGE_DIRECTORY_ENTRY_DELAY_IMPORT = 13   # Delay Load Import Descriptors
        IMAGE_DIRECTORY_ENTRY_COM_DESCRIPTOR = 14   # COM Runtime descriptor
    }
 
    [Flags()] enum IMAGE_SCN {
        #       IMAGE_SCN_TYPE_REG                   0x00000000  #  Reserved.
        #       IMAGE_SCN_TYPE_DSECT                 0x00000001  #  Reserved.
        #       IMAGE_SCN_TYPE_NOLOAD                0x00000002  #  Reserved.
        #       IMAGE_SCN_TYPE_GROUP                 0x00000004  #  Reserved.
        IMAGE_SCN_TYPE_NO_PAD = 0x00000008  #  Reserved.
        #       IMAGE_SCN_TYPE_COPY                  0x00000010  #  Reserved.
 
        IMAGE_SCN_CNT_CODE = 0x00000020  #  Section contains code.
        IMAGE_SCN_CNT_INITIALIZED_DATA = 0x00000040  #  Section contains initialized data.
        IMAGE_SCN_CNT_UNINITIALIZED_DATA = 0x00000080  #  Section contains uninitialized data.
 
        IMAGE_SCN_LNK_OTHER = 0x00000100  #  Reserved.
        IMAGE_SCN_LNK_INFO = 0x00000200  #  Section contains comments or some other type of information.
        #       IMAGE_SCN_TYPE_OVER                  0x00000400  #  Reserved.
        IMAGE_SCN_LNK_REMOVE = 0x00000800  #  Section contents will not become part of image.
        IMAGE_SCN_LNK_COMDAT = 0x00001000  #  Section contents comdat.
        #                                            0x00002000  #  Reserved.
        #       IMAGE_SCN_MEM_PROTECTED - Obsolete =  0x00004000
        IMAGE_SCN_NO_DEFER_SPEC_EXC = 0x00004000  #  Reset speculative exceptions handling bits in the TLB entries for this section.
        IMAGE_SCN_GPREL = 0x00008000  #  Section content can be accessed relative to GP
        IMAGE_SCN_MEM_FARDATA = 0x00008000
        #       IMAGE_SCN_MEM_SYSHEAP  - Obsolete    0x00010000
        IMAGE_SCN_MEM_PURGEABLE = 0x00020000
        IMAGE_SCN_MEM_16BIT = 0x00020000
        IMAGE_SCN_MEM_LOCKED = 0x00040000
        IMAGE_SCN_MEM_PRELOAD = 0x00080000
 
        IMAGE_SCN_ALIGN_1BYTES = 0x00100000  # 
        IMAGE_SCN_ALIGN_2BYTES = 0x00200000  # 
        IMAGE_SCN_ALIGN_4BYTES = 0x00300000  # 
        IMAGE_SCN_ALIGN_8BYTES = 0x00400000  # 
        IMAGE_SCN_ALIGN_16BYTES = 0x00500000  #  Default alignment if no others are specified.
        IMAGE_SCN_ALIGN_32BYTES = 0x00600000  # 
        IMAGE_SCN_ALIGN_64BYTES = 0x00700000  # 
        IMAGE_SCN_ALIGN_128BYTES = 0x00800000  # 
        IMAGE_SCN_ALIGN_256BYTES = 0x00900000  # 
        IMAGE_SCN_ALIGN_512BYTES = 0x00A00000  # 
        IMAGE_SCN_ALIGN_1024BYTES = 0x00B00000  # 
        IMAGE_SCN_ALIGN_2048BYTES = 0x00C00000  # 
        IMAGE_SCN_ALIGN_4096BYTES = 0x00D00000  # 
        IMAGE_SCN_ALIGN_8192BYTES = 0x00E00000  # 
        #  Unused                                    0x00F00000
        IMAGE_SCN_ALIGN_MASK = 0x00F00000
 
        IMAGE_SCN_LNK_NRELOC_OVFL = 0x01000000  #  Section contains extended relocations.
        IMAGE_SCN_MEM_DISCARDABLE = 0x02000000  #  Section can be discarded.
        IMAGE_SCN_MEM_NOT_CACHED = 0x04000000  #  Section is not cachable.
        IMAGE_SCN_MEM_NOT_PAGED = 0x08000000  #  Section is not pageable.
        IMAGE_SCN_MEM_SHARED = 0x10000000  #  Section is shareable.
        IMAGE_SCN_MEM_EXECUTE = 0x20000000  #  Section is executable.
        IMAGE_SCN_MEM_READ = 0x40000000  #  Section is readable.
        IMAGE_SCN_MEM_WRITE = 0x80000000  #  Section is writeable.
 
        # 
        #  TLS Characteristic Flags
        # 
        IMAGE_SCN_SCALE_INDEX = 0x00000001  #  Tls index is scaled
 
    }
 
    Function Convert-EnumToString([Enum]$enum) {
        $type = [Type]$enum
    }
    $IMAGE_DOS_HEADER = New-Object System.Collections.Specialized.OrderedDictionary
 
    $IMAGE_DOS_HEADER.Add("e_magic", [Uint16]0)                     # magic number
    $IMAGE_DOS_HEADER.Add("e_cblp", [UInt16]0)                      # Bytes on last page of file
    $IMAGE_DOS_HEADER.Add("e_cp", [UInt16]0)                        # Pages in file
    $IMAGE_DOS_HEADER.Add("e_crlc", [UInt16]0)                      # Relocations
    $IMAGE_DOS_HEADER.Add("e_cparhdr", [UInt16]0)                   # Size of header in paragraphs
    $IMAGE_DOS_HEADER.Add("e_minalloc", [UInt16]0)                  # Minimum extra paragraphs needed
    $IMAGE_DOS_HEADER.Add("e_maxalloc", [UInt16]0)                  # Maximum extra paragraphs needed
    $IMAGE_DOS_HEADER.Add("e_ss", [UInt16]0)                        # Initial (relative) SS value
    $IMAGE_DOS_HEADER.Add("e_sp", [UInt16]0)                        # Initial SP value
    $IMAGE_DOS_HEADER.Add("e_csum", [UInt16]0)                      # Checksum
    $IMAGE_DOS_HEADER.Add("e_ip", [UInt16]0)                        # Initial IP value
    $IMAGE_DOS_HEADER.Add("e_cs", [UInt16]0)                        # Initial (relative) CS value
    $IMAGE_DOS_HEADER.Add("e_lfarlc", [UInt16]0)                    # File address of relocation table
    $IMAGE_DOS_HEADER.Add("e_ovno", [UInt16]0)                      # Overlay number
    $IMAGE_DOS_HEADER.Add("e_res", (New-Object UInt16[] 4))         # Reserved words
    $IMAGE_DOS_HEADER.Add("e_oemid", [UInt16]0)                     # OEM identifier (for e_oeminfo)
    $IMAGE_DOS_HEADER.Add("e_oeminfo", [UInt16]0)                   # OEM information,[UInt16]0) e_oemid specific
    $IMAGE_DOS_HEADER.Add("e_res2[10]", (New-Object UInt16[] 10))   # Reserved words
    $IMAGE_DOS_HEADER.Add("e_lfanew", [Uint32]0)                    # File address of new exe header
 
    $IMAGE_FILE_HEADER = New-Object System.Collections.Specialized.OrderedDictionary
    $IMAGE_FILE_HEADER.Add("Machine", [UInt16]0)
    $IMAGE_FILE_HEADER.Add("NumberOfSections", [UInt16]0)
    $IMAGE_FILE_HEADER.Add("TimeDateStamp", [UInt32]0)
    $IMAGE_FILE_HEADER.Add("PointerToSymbolTable", [UInt32]0)
    $IMAGE_FILE_HEADER.Add("NumberOfSymbols", [UInt32]0)
    $IMAGE_FILE_HEADER.Add("SizeOfOptionalHeader", [UInt16]0)
    $IMAGE_FILE_HEADER.Add("Characteristics", [UInt16]0)
 
    $IMAGE_OPTIONAL_HEADER = New-Object System.Collections.Specialized.OrderedDictionary
 
    $IMAGE_OPTIONAL_HEADER.Add("Magic", [Uint16]0)
    $IMAGE_OPTIONAL_HEADER.Add("MajorLinkerVersion", [Byte]0)
    $IMAGE_OPTIONAL_HEADER.Add("MinorLinkerVersion", [Byte]0)
    $IMAGE_OPTIONAL_HEADER.Add("SizeOfCode", [Uint32]0)
    $IMAGE_OPTIONAL_HEADER.Add("SizeOfInitializedData", [Uint32]0)
    $IMAGE_OPTIONAL_HEADER.Add("SizeOfUninitializedData", [Uint32]0)
    $IMAGE_OPTIONAL_HEADER.Add("AddressOfEntryPoint", [Uint32]0)
    $IMAGE_OPTIONAL_HEADER.Add("BaseOfCode", [Uint32]0)
    $IMAGE_OPTIONAL_HEADER.Add("BaseOfData", [Uint32]0)
 
    # NT Additional Fields
 
    $IMAGE_OPTIONAL_HEADER.Add("ImageBase", [Uint32]0)
    $IMAGE_OPTIONAL_HEADER.Add("SectionAlignment", [Uint32]0)
    $IMAGE_OPTIONAL_HEADER.Add("FileAlignment", [Uint32]0)
    $IMAGE_OPTIONAL_HEADER.Add("MajorOperatingSystemVersion", [Uint16]0)
    $IMAGE_OPTIONAL_HEADER.Add("MinorOperatingSystemVersion", [Uint16]0)
    $IMAGE_OPTIONAL_HEADER.Add("MajorImageVersion", [Uint16]0)
    $IMAGE_OPTIONAL_HEADER.Add("MinorImageVersion", [Uint16]0)
    $IMAGE_OPTIONAL_HEADER.Add("MajorSubsystemVersion", [Uint16]0)
    $IMAGE_OPTIONAL_HEADER.Add("MinorSubsystemVersion", [Uint16]0)
    $IMAGE_OPTIONAL_HEADER.Add("Win32VersionValue", [Uint32]0)
    $IMAGE_OPTIONAL_HEADER.Add("SizeOfImage", [Uint32]0)
    $IMAGE_OPTIONAL_HEADER.Add("SizeOfHeaders", [Uint32]0)
    $IMAGE_OPTIONAL_HEADER.Add("CheckSum", [Uint32]0)
    $IMAGE_OPTIONAL_HEADER.Add("Subsystem", [Uint16]0)
    $IMAGE_OPTIONAL_HEADER.Add("DllCharacteristics", [Uint16]0)
    $IMAGE_OPTIONAL_HEADER.Add("SizeOfStackReserve", [Uint32]0)
    $IMAGE_OPTIONAL_HEADER.Add("SizeOfStackCommit", [Uint32]0)
    $IMAGE_OPTIONAL_HEADER.Add("SizeOfHeapReserve", [Uint32]0)
    $IMAGE_OPTIONAL_HEADER.Add("SizeOfHeapCommit", [Uint32]0)
    $IMAGE_OPTIONAL_HEADER.Add("LoaderFlags", [Uint32]0)
    $IMAGE_OPTIONAL_HEADER.Add("NumberOfRvaAndSizes", [Uint32]0)
    $IMAGE_OPTIONAL_HEADER.Add("DataDirectory", (New-Object System.Collections.Specialized.OrderedDictionary[] $IMAGE_NUMBEROF_DIRECTORY_ENTRIES))
    For ($i = 0; $i -lt $IMAGE_OPTIONAL_HEADER["DataDirectory"].Count; $i++) {
        $IMAGE_OPTIONAL_HEADER["DataDirectory"][$i] = New-Object System.Collections.Specialized.OrderedDictionary
        $IMAGE_OPTIONAL_HEADER["DataDirectory"][$i].Add("VirtualAddress", [Uint32]0)
        $IMAGE_OPTIONAL_HEADER["DataDirectory"][$i].Add("Size", [UINt32]0)
    }
 
 
    $IMAGE_OPTIONAL_HEADER64 = New-Object System.Collections.Specialized.OrderedDictionary
    $IMAGE_OPTIONAL_HEADER64.Add("Magic", [Uint16]0)
    $IMAGE_OPTIONAL_HEADER64.Add("MajorLinkerVersion", [Byte]0)
    $IMAGE_OPTIONAL_HEADER64.Add("MinorLinkerVersion", [Byte]0)
    $IMAGE_OPTIONAL_HEADER64.Add("SizeOfCode", [Uint32]0)
    $IMAGE_OPTIONAL_HEADER64.Add("SizeOfInitializedData", [Uint32]0)
    $IMAGE_OPTIONAL_HEADER64.Add("SizeOfUninitializedData", [Uint32]0)
    $IMAGE_OPTIONAL_HEADER64.Add("AddressOfEntryPoint", [Uint32]0)
    $IMAGE_OPTIONAL_HEADER64.Add("BaseOfCode", [Uint32]0)
    $IMAGE_OPTIONAL_HEADER64.Add("ImageBase", [Uint64]0)
    $IMAGE_OPTIONAL_HEADER64.Add("SectionAlignment", [Uint32]0)
    $IMAGE_OPTIONAL_HEADER64.Add("FileAlignment", [Uint32]0)
    $IMAGE_OPTIONAL_HEADER64.Add("MajorOperatingSystemVersion", [Uint16]0)
    $IMAGE_OPTIONAL_HEADER64.Add("MinorOperatingSystemVersion", [Uint16]0)
    $IMAGE_OPTIONAL_HEADER64.Add("MajorImageVersion", [Uint16]0)
    $IMAGE_OPTIONAL_HEADER64.Add("MinorImageVersion", [Uint16]0)
    $IMAGE_OPTIONAL_HEADER64.Add("MajorSubsystemVersion", [Uint16]0)
    $IMAGE_OPTIONAL_HEADER64.Add("MinorSubsystemVersion", [Uint16]0)
    $IMAGE_OPTIONAL_HEADER64.Add("Win32VersionValue", [Uint32]0)
    $IMAGE_OPTIONAL_HEADER64.Add("SizeOfImage", [Uint32]0)
    $IMAGE_OPTIONAL_HEADER64.Add("SizeOfHeaders", [Uint32]0)
    $IMAGE_OPTIONAL_HEADER64.Add("CheckSum", [Uint32]0)
    $IMAGE_OPTIONAL_HEADER64.Add("Subsystem", [Uint16]0)
    $IMAGE_OPTIONAL_HEADER64.Add("DllCharacteristics", [Uint16]0)
    $IMAGE_OPTIONAL_HEADER64.Add("SizeOfStackReserve", [Uint64]0)
    $IMAGE_OPTIONAL_HEADER64.Add("SizeOfStackCommit", [Uint64]0)
    $IMAGE_OPTIONAL_HEADER64.Add("SizeOfHeapReserve", [Uint64]0)
    $IMAGE_OPTIONAL_HEADER64.Add("SizeOfHeapCommit", [Uint64]0)
    $IMAGE_OPTIONAL_HEADER64.Add("LoaderFlags", [Uint32]0)
    $IMAGE_OPTIONAL_HEADER64.Add("NumberOfRvaAndSizes", [Uint32]0)
    $IMAGE_OPTIONAL_HEADER64.Add("DataDirectory", (New-Object System.Collections.Specialized.OrderedDictionary[] $IMAGE_NUMBEROF_DIRECTORY_ENTRIES))
    For ($i = 0; $i -lt $IMAGE_OPTIONAL_HEADER64["DataDirectory"].Count; $i++) {
        $IMAGE_OPTIONAL_HEADER64["DataDirectory"][$i] = New-Object System.Collections.Specialized.OrderedDictionary
        $IMAGE_OPTIONAL_HEADER64["DataDirectory"][$i].Add("VirtualAddress", [Uint32]0)
        $IMAGE_OPTIONAL_HEADER64["DataDirectory"][$i].Add("Size", [UINt32]0)
    }
 
    $IMAGE_SECTION_HEADER = New-Object System.Collections.Specialized.OrderedDictionary
    $IMAGE_SECTION_HEADER.Add("Name", (New-Object Byte[] $IMAGE_SIZEOF_SHORT_NAME))
    $IMAGE_SECTION_HEADER.Add("Misc.PhysicalAddress", [Uint32]0)
    $IMAGE_SECTION_HEADER.Add("Misc.VirtualSize", [Uint32]0)
    $IMAGE_SECTION_HEADER.Add("VirtualAddress", [Uint32]0)
    $IMAGE_SECTION_HEADER.Add("SizeOfRawData", [Uint32]0)
    $IMAGE_SECTION_HEADER.Add("PointerToRawData", [Uint32]0)
    $IMAGE_SECTION_HEADER.Add("PointerToRelocations", [Uint32]0)
    $IMAGE_SECTION_HEADER.Add("PointerToLinenumbers", [Uint32]0)
    $IMAGE_SECTION_HEADER.Add("NumberOfRelocations", [Uint16]0)
    $IMAGE_SECTION_HEADER.Add("NumberOfLinenumbers", [Uint16]0)
    $IMAGE_SECTION_HEADER.Add("Characteristics", [Uint32]0)
 
    Function Convert-EnumToString {
        param($enum, $value)
     
        $builder = New-Object System.Text.StringBuilder
        $names = ($enum.DeclaredFields | Select-Object -Property Name | Where-Object { $_.Name -ne "value__" }).Name
 
        ForEach ($name in $names) {
            if (!($value -ne 0 -and [Enum]::Parse($enum, $name).value__ -eq 0)) {
                if ((([Enum]::Parse($enum, $name).value__) -band $value) -eq ([Enum]::Parse($enum, $name).value__)) {
                    if ($builder.Length -gt 0) {
                        [void]$builder.Append(" | ")
                    }
                    [void]$builder.Append($name)
                }
            }
        }
 
        return $builder.ToString()
     
    }
    Function Read-BinaryFile {
        param(
            [System.IO.BinaryReader][ref]$reader,
            [System.Collections.Specialized.OrderedDictionary][ref]$items)
    
    
        $keys = New-Object String[] $items.Count
        $items.Keys.CopyTo($keys, 0)
   
        for ($i = 0; $i -lt $items.Count; $i++) {
            $item = $keys[$i]
        
            if ($items[$item] -is [Array]) {
                if ($items[$item][0] -is [System.Collections.Specialized.OrderedDictionary]) {
                    ForEach ($subItem in $items[$item]) {
                        Read-BinaryFile -reader ([ref]$reader) -items ([ref]$subItem)
                    }
                }
                else {
                    $currentItem = $items[$item][0]
                    For ($j = 0; $j -lt $items[$item].Length; $j++) {
                        switch ($currentItem.GetType().Name) {
                            "Byte" {
                                $items[$item][$j] = $reader.ReadByte()
                            }
                            "Uint16" { 
                                $items[$item][$j] = $Reader.ReadUint16()
                            }
                            "Uint32" {
                                $items[$item][$j] = $reader.ReadUInt32()
                            }
                            "Uint64" { 
                                $items[$item][$j] = $Reader.ReadUInt64()
                            }
                            default { "Unknown Type! $($currentItem.GetType().Name)" }
                        }
                    }
                }
            }
            else {
                $currentItem = $items[$item]
                if ($currentItem -is [System.Collections.Specialized.OrderedDictionary]) {
                    Read-BinaryFile -reader ([ref]$reader) -items ([ref]$items[$item])
                }
                else {
                    switch ($currentItem.GetType().Name) {
                        "Byte" {
                            $items[$item] = $reader.ReadByte()
                        }
 
                        "Uint16" { 
                            $items[$item] = $reader.ReadUint16()
 
                        }
                        "Uint32" { 
                            $items[$item] = $reader.ReadUint32()
                        }
                        "Uint64" {
                            $items[$item] = $reader.ReadUint64()               
                        }
                        default { "Unknown Type! $($currentItem.GetType().Name)" }
                    }
                }
            }
        }
    }
 
 
    $FileStream = $null
    $BinaryReader = $null
    try {
        $FileStream = [System.IO.File]::Open($filename, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, ([System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete))
        $BinaryReader = New-Object System.IO.BinaryReader($FileStream)

        # A valid DOS header is 64 bytes and holds e_lfanew at offset 0x3C.
        if ($FileStream.Length -lt 64) {
            return "Not a valid PE file!"
        }

        [void]$BinaryReader.BaseStream.Seek(0, [System.IO.SeekOrigin]::Begin)
        Read-BinaryFile -reader ([ref]$BinaryReader) -Items ([ref]$IMAGE_DOS_HEADER)

        if ($IMAGE_DOS_HEADER["e_magic"] -ne $IMAGE_DOS_SIGNATURE) {
            return "Not a valid PE file!"
        }

        # e_lfanew must sit past the DOS header and leave room for the PE signature,
        # the file header and the optional-header magic.
        $e_lfanew = [int]$IMAGE_DOS_HEADER["e_lfanew"]
        if ($e_lfanew -lt 64 -or ($e_lfanew + 26) -gt $FileStream.Length) {
            return "Not a valid PE file!"
        }

        # Validate the PE signature ("PE\0\0") before reading the optional-header magic.
        [void]$BinaryReader.BaseStream.Seek($e_lfanew, [System.IO.SeekOrigin]::Begin)
        if ($BinaryReader.ReadUInt32() -ne 0x00004550) {
            return "Not a valid PE file!"
        }

        [void]$BinaryReader.BaseStream.Seek($e_lfanew + 24, [System.IO.SeekOrigin]::Begin)
        $magic = $BinaryReader.ReadUInt16()

        switch ($magic) {
            $IMAGE_NT_OPTIONAL_HDR32_MAGIC { return "32-bit" }
            $IMAGE_NT_OPTIONAL_HDR64_MAGIC { return "64-bit" }
            $IMAGE_ROM_OPTIONAL_HDR_MAGIC { return "ROM File, not supported!" }
            default { return "Unknown PE file type $($magic)!" }
        }
    }
    catch {
        return "Unreadable: $($_.Exception.Message)"
    }
    finally {
        if ($BinaryReader) { $BinaryReader.Close() }
        if ($FileStream) { $FileStream.Close() }
    }
}

[string]$teststring = [System.Uri]::UnescapeDataString('||strFiles||')
$filenames = $teststring -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
foreach ($filename in $filenames) {
    $path = $filename
    if (-not [Environment]::Is64BitProcess) {
        # A 32-bit process sees \System32\ redirected to SysWOW64; use Sysnative to reach the 64-bit file.
        $path = $path -replace '\\System32\\', '\Sysnative\'
    }
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        $Arch = Get-PEInfo -filename $path
        Write-Output "$filename|$Arch"
    }
    else {
        Write-Output "$filename|File not found!"
    }
}
