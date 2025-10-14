function Get-TaniumClientSize {
    [cmdletbinding()]
    param(
        [parameter(mandatory=$true)]
        [string]$Path,
        [switch]$Recurse
    )
    if ($Recurse.IsPresent) {
        $SizeInGb = ((Get-ChildItem –Force -Path $Path –Recurse -ErrorAction SilentlyContinue| Measure-Object -Property Length -Sum).sum / 1Gb)
    }
    else {
        $SizeInGb = ((Get-ChildItem –Force -Path $Path -ErrorAction SilentlyContinue| Measure-Object -Property Length -Sum).sum / 1Gb)
    }
    $Properties = @{ 
        Path = $Path
        Size = '{0:N2} GB' -f $SizeInGB
    }
    $Size = New-Object -TypeName PSObject -Property $Properties
    $Size
}