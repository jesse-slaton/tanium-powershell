class PackageMetadata {
    [string]$Vendor
    [string]$ProductName
    [string]$ProductVersion
    [string]$Architecture
    [int]$DiskSpaceMB
    [int]$MemoryMB
    [string]$DownloadUrl
    [string]$SHA256
    [string]$AdditionalDetails
    [hashtable]$InstallOperation
    [hashtable]$RemoveOperation
    [hashtable]$OsRequirements
    [hashtable]$SelfService
    [string]$InstallRequirements
    [string]$InstallVerification
    [string]$UpdateDetection

    PackageMetadata() {
        # Initialize with defaults
        $this.MemoryMB = 512
        $this.OsRequirements = @{
            editionId   = $null
            productName = $null
            build       = $null
        }
    }

    [hashtable] ToHashtable() {
        return @{
            vendor               = $this.Vendor
            productName          = $this.ProductName
            productVersion       = $this.ProductVersion
            architecture         = $this.Architecture
            diskSpaceMB          = $this.DiskSpaceMB
            memoryMB             = $this.MemoryMB
            downloadUrl          = $this.DownloadUrl
            sha256               = $this.SHA256
            additionalDetails    = $this.AdditionalDetails
            installOperation     = $this.InstallOperation
            removeOperation      = $this.RemoveOperation
            osRequirements       = $this.OsRequirements
            selfService          = $this.SelfService
            installRequirements  = $this.InstallRequirements
            installVerification  = $this.InstallVerification
            updateDetection      = $this.UpdateDetection
        }
    }

    [void] Validate() {
        if ([string]::IsNullOrWhiteSpace($this.Vendor)) {
            throw "Vendor is required"
        }
        if ([string]::IsNullOrWhiteSpace($this.ProductName)) {
            throw "ProductName is required"
        }
        if ([string]::IsNullOrWhiteSpace($this.ProductVersion)) {
            throw "ProductVersion is required"
        }
        if ([string]::IsNullOrWhiteSpace($this.Architecture)) {
            throw "Architecture is required"
        }
        if ($this.DiskSpaceMB -le 0) {
            throw "DiskSpaceMB must be greater than 0"
        }
        if ($this.MemoryMB -le 0) {
            throw "MemoryMB must be greater than 0"
        }
        if ($null -eq $this.InstallOperation -or $this.InstallOperation.Count -eq 0) {
            throw "InstallOperation is required"
        }
        if ($null -eq $this.RemoveOperation -or $this.RemoveOperation.Count -eq 0) {
            throw "RemoveOperation is required"
        }
        if ([string]::IsNullOrWhiteSpace($this.InstallRequirements)) {
            throw "InstallRequirements is required"
        }
        if ([string]::IsNullOrWhiteSpace($this.InstallVerification)) {
            throw "InstallVerification is required"
        }
    }
}
