# PowerShell Script to parse cbs.log file and return lines matching specific patterns

# Define the file path
$cbsLogFilePath = "C:\Windows\Logs\CBS\CBS.log"

# Define the output file path
$outputFilePath = "C:\support\logs\parsedcbs.csv"

# Define the regex patterns
$linePattern = "^\s*\[SR\].*(Repairing|Corrupted|Cannot Repair|Repaired)"
$parsingPattern = "^([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]|[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]\.[0-9][0-9][0-9]), (\w+)\s+(\w+)\s+(.*)"

# Ensure output directory exists
$outputDirectory = Split-Path -Path $outputFilePath -Parent
if (-not (Test-Path -Path $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}

# Read the cbs.log file and find lines that match the linePattern
$matchingLines = Get-Content -Path $cbsLogFilePath | Where-Object { $_ -match $linePattern }

# Initialize an empty array to store the parsed results as objects
$results = @()

# Iterate through the matching lines, parse them, and store them as objects in the results array
$matchingLines | ForEach-Object {
    if ($_ -match $parsingPattern) {
        $dateTimeString = $Matches[1]
        $dateTime = Get-Date -Date $dateTimeString
        $rfc822DateTime = $dateTime.ToString("ddd, dd MMM yyyy HH:mm:ss zzz")
        $logLevel = $Matches[2]
        $source = $Matches[3]
        $resultString = $Matches[4]

        # Create an object with ordered properties and add it to the results array
        $resultObject = [PSCustomObject]@{
            DateTime = $rfc822DateTime
            LogLevel = $logLevel
            Source = $source
            ResultString = $resultString
        }
        $results += $resultObject
    }
}

# Check if the $results array is empty
if ($results.Count -eq 0) {
    $dateTime = Get-Date
    $rfc822DateTime = $dateTime.ToString("ddd, dd MMM yyyy HH:mm:ss zzz")    
    # Create a custom object with ordered properties and the desired message
    $noResultsObject = [PSCustomObject]@{
        DateTime = $rfc822DateTime
        LogLevel = 'Information'
        Source = 'Tanium Package'
        ResultString = 'No SFC Repairs or Corruption Found'
    }

    # Add the custom object to the $results array
    $results += $noResultsObject
}

# Export the results array to the specified CSV file, overwriting if it already exists
$results | Export-Csv -Path $outputFilePath -NoTypeInformation -Force
