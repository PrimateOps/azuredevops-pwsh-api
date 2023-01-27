<#
Build Settings file (concept borrowed from PowerShellBuild - https://github.com/psake/PowerShellBuild)

Values in this file can be adjusted to control the build settings
#>
$projectRoot = $env:BHProjectPath
$pipelineRun = ([string]::IsNullOrWhiteSpace($env:TF_BUILD)) ? $false : $true

@{
    # General
    moduleName        = $env:BHProjectName
    moduleSourcePath  = $env:BHModulePath
    psVersion         = $PSVersionTable.psVersion.ToString()
    buildOutput       = ($pipelineRun)? $env:BUILD_ARTIFACTSTAGINGDIRECTORY : $env:BHBuildOutput
    moduleVersion     = ($pipelineRun)?	$env:BUILD_BUILDNUMBER : ('0.0.1-Alpha{0}' -f (git rev-parse --short HEAD))
    
    # Pester Test specific
    runPesterTests    = $true
    testsDir          = [IO.Path]::Combine($projectRoot, 'tests')
    testsOutputFile   = [IO.Path]::Combine($projectRoot, 'testResults.xml')
    testsOutputFormat = 'NUnitXml'
    
}