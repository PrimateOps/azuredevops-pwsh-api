<#
.SYNOPSIS
Common initialisation script that can be dot sourced in top level BeforeAll {} script blocks of Pester 
test scripts.

.DESCRIPTION
This is a common initialisation header that can be used for ALL pester tests. It standardises the approach, 
reduces duplication of code and allows us to update the header logic without having to do it in every test 
script within the project.

.PARAMETER Path
The path to the {script}.tests.ps1 file that is being tested.
#>
[cmdletBinding()]
param(
    [Parameter(Mandatory,Position=0)]
    [ValidateScript({
        if (-not(Test-Path -Path $_)){
            throw ("Path to Test script [{0}] does not exist" -f $_)
        }else{
            return $true
        }
    })]
    [string]$Path
)

    # Leverage the build variables provided by BuildHelpers module (exposed at build time)

    # get a handle of the script to be tested through convention (case insensitive replace):
    $sut = ((((($Path.ToLower()).Replace('\tests\','\{0}\' -f $env:BHProjectName)).Replace('_psm1.tests.ps1','.psm1')).Replace('_psd1.tests.ps1','.psd1')).replace('.json.tests.ps1','.json')).replace('.tests.ps1','.ps1')
    
    # get a handle to the module name for use in some tests
    $moduleName = $env:BHProjectName
    
    # determine what to do here - dot source if .ps1 or import if datafile/module
    switch($sut){
        {$_.endswith('.ps1')}   {
                                    . $sut
                                    $functionName = (Split-Path $sut -Leaf).Replace('.ps1','')
                                    break
                                }
        {$_.endswith('.psd1')}  {
                                    $dataFile = Import-PowerShellDataFile -Path $sut
                                    break
                                }
        {$_.endswith('.psm1')}  {
                                    Import-Module $sut
                                    break
                                }
        {$_.endswith('.json')}  {
                                    $psObject = (Get-Content -Path $sut | ConvertFrom-Json -depth 50)
                                    break 
                                }
    }