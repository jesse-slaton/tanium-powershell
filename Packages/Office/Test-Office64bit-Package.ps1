$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\OUTLOOK.EXE"
if(!(Test-Path -Path $RegPath)) {
    Write-Error 'Outlook not installed. Please reinstall Office!'
    #[Environment]::Exit(20)
    }
Else {
    $Path = (Get-ItemProperty -LiteralPath $RegPath).'(default)'
    }

[int32]$MACHINE_OFFSET = 4
[int32]$PE_POINTER_OFFSET = 60

[byte[]]$data = New-Object -TypeName System.Byte[] -ArgumentList 4096
$stream = New-Object -TypeName System.IO.FileStream -ArgumentList ($path, 'Open', 'Read')
$stream.Read($data, 0, 4096) | Out-Null

[int32]$PE_HEADER_ADDR = [System.BitConverter]::ToInt32($data, $PE_POINTER_OFFSET)
[int32]$machineUint = [System.BitConverter]::ToUInt16($data, $PE_HEADER_ADDR + $MACHINE_OFFSET)
$stream.Close()

$result = "" | select Path, FileType, Is64Bit
$result.path = $path
$result.Is64Bit = $false

switch ($machineUint) 
{
    0      { $result.FileType = 'Native' }
    0x014c { $result.FileType = 'x86' }
    0x0200 { $result.FileType = 'Itanium' }
    0x8664 { $result.FileType = 'x64'; $result.is64Bit = $true; }
}

$result.Is64Bit

