[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [String]$manifestPath,
    [Parameter(Mandatory)]
    [String]$version
)

    Write-Host ("Incoming Version value [{0}]" -f $version)
    # check if there's a pre-release tag present
    if ($version.contains('-')){
        Write-Host ("Pre-Release tag detected. Splitting version to include pre-release tag in module manifest...")
        # work out the start index of preRelease ('-')
        $tagStartIndex = $version.IndexOf('-')

        # version value that PowerShell Module will accept is to the left of the '-'
        $semVerValue = $version.Substring(0,$tagStartIndex)

        # everything else to the right of the '-' is what we'll capture as the pre-release value
        # as we are starting to the right of '-', we need to move the start index over by one
        $preStartIndex = $tagStartIndex + 1
        # Substring method needs the start index, and the length of characters to grab. Work that out by:
        $subStrLength = $version.Length - $preStartIndex

        # extract the preRelease value, and strip out any non-alphanumeric characters
        $preRelease = (($version.Substring($preStartIndex,$subStrLength)) -replace '\W', '')
        
        # reset version value to just include the semver without prerelease
        $version = $semVerValue
        $preRelease = $preRelease

        Write-Host ("Module Version will be set to: [{0}]" -f $version)
        Write-Host ("Pre-Release tag will be set to: [{0}]" -f $preRelease)
    }
    # validate manifest path
    Write-Host ("Validating Module Manifest path: [{0}]" -f $manifestPath)
    if (-not(Test-Path $manifestPath)){
        throw ('Module manifest not found at {0}' -f $manifestPath)
    }#if

    # validate that the version can convert to an actual Version object
    try{
        Write-Host ('Validating incoming version format - Version set to [{0}]' -f $version)
        $versionValid = [version]::new($version)

    }catch{
        $ex = $_

        Write-Error ('##[error]Could not set Version object - error:')
        throw $ex
    }#try/catch

    # set the version
    $versionParameters = @{
        path = $manifestPath
        moduleVersion = $version
    }
    if (-not([string]::IsNullOrWhiteSpace($preRelease))){
        # preRelease tag included. Set that too
        $versionParameters.add('Prerelease',$preRelease)
    }#if
    
    try{
        Update-ModuleManifest @versionParameters -ErrorAction Stop
    }catch{
        $ex = $_

        Write-Error ('##[error]Failed to update module manifest file. Error follows.')
        throw $ex
    }#try/catch

    try{
        $manifestTest = Test-ModuleManifest -Path $manifestPath -ErrorAction Stop
    }catch{
        $ex = $_

        Write-Error ('##[error]Failed on testing manifest file. Error follows.')
        throw $ex
    }#try/catch

    # validate input
    $versionGood = $version -eq $manifestTest.Version
    Write-Host ('Module version is good? ... [{0}]' -f $versionGood)
    if (-not([string]::IsNullOrWhiteSpace($preRelease))){
        $preReleaseGood = $preRelease -eq $manifestTest.PrivateData.PSData.Prerelease
        Write-Host ('Module preRelease tag is good? ... [{0}]' -f $preReleaseGood)
    }