# We are leveraging concepts from an open-source project on GitHub - /psake/PowerShellBuild (https://github.com/psake/PowerShellBuild)  
# All kudos go to the author/contributors of that project. In some cases, we are flat out copying logic
properties {
    # BH* env variables are prefilled by the BuildHelpers module - step executed in build.ps1 script which invokes this script.
    
    $settings = . ([IO.Path]::Combine($PSScriptRoot, 'build.settings.ps1'))

}

task default -depends Init

task Init {

    Write-Host "`nEnvironment variables:" -ForegroundColor Yellow
    (Get-Item ENV:BH*).Foreach({
            '{0,-20}{1}' -f $_.name, $_.value
    })

    Write-Host "`nBuild-Time parameters:" -ForegroundColor Yellow
    $settings.getenumerator().foreach({
        '{0,-20}{1}' -f $_.key, $_.value
    })

} -description 'Initialise Build Environment'

task Clean -depends Init {
    if (Test-Path $settings.buildOutput) {
        Remove-Item -Path $settings.buildOutput -Recurse -Force -Verbose:$false
    }
} -description 'Clear the Output folder'

task Stage -depends Clean {
    
    $stageParams = @{
        ModuleSource = $settings.moduleSourcePath
        OutputPath   = $settings.buildOutput
    }

    . ([IO.Path]::Combine($projectRoot, '.helpers\localPublishModule.ps1')) @stageParams
    
    # if running in the context of a pipeline, get the GitVer value, otherwise, leave as is (local run)
    Write-Host ('Setting module version. Detecting run context...')
    
    Write-Host ('Pipeline Context: [{0}]. Module version will be set to [{1}].' -f $pipelineRun,$settings.moduleVersion)
        
    $versionParams = @{
        manifestPath = ('{0}\{1}\{2}.psd1' -f $settings.buildOutput, $settings.moduleName, $settings.moduleName)
        version = $settings.moduleVersion
    }
    
    # set the version
    . ([IO.Path]::Combine($projectRoot, '.helpers\setModuleVersion.ps1')) @versionParams

} -description 'Stage the module content before building'

$pesterPreReqs = {
    $result = $true
    if (-not $settings.runPesterTests) {
        Write-Warning 'Pester testing is not enabled.'
        $result = $false
    }
    if (-not (Get-Module -Name Pester -ListAvailable)) {
        Write-Warning 'Pester module is not installed'
        $result = $false
    }
    if (-not (Test-Path -Path $settings.testsDir)) {
        Write-Warning "Test directory [$($settings.testsDir)] not found"
        $result = $false
    }
    return $result
}

task Pester -depends Init -precondition $pesterPreReqs{
    try{
        Import-Module Pester -MinimumVersion 5.0.0 -ErrorAction Stop
    }catch{
        $ex = $_

        Write-Error "Could not load Pester module:`n"
        throw $ex
    }

    $configuration = [PesterConfiguration]::Default
    $configuration.Output.Verbosity        = 'Detailed'
    $configuration.Run.Path                = $settings.testsDir
    $configuration.Run.PassThru            = $true
    $configuration.TestResult.Enabled      = -not [string]::IsNullOrEmpty($settings.testsOutputFile)
    $configuration.TestResult.OutputPath   = $settings.testsOutputFile
    $configuration.TestResult.OutputFormat = $settings.testsOutputFormat

    # execute  tests
    $testResults = Invoke-Pester -Configuration $configuration

    # check for failures
    if ($testResults.FailedCount -gt 0){
        if ($pipelineRun){
            Write-Host "##[error]One or more Pester Tests failed"
        }else{
            Write-Error "One or more Pester tests failed"
        }
        throw '##[error]Testing Failed'
    }

} -description 'Execute Pester tests'
