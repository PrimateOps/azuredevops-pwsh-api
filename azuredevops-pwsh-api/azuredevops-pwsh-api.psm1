<#
Any infromation (variables, functions etc...) that need to be made available module-wide need to go into this .psm1
file - loading them here will make them available to functions across the module.

Keep in mind - ScriptsToProcess is loaded *before* the main module file (i.e. before any module-wide variables or manifest 
information can be come available)

#>
  # expose the module root directory to all functions in the module
  $script:moduleRoot = $PSScriptRoot
  $script:moduleName = Split-Path $moduleRoot -Leaf

<#
.DESCRIPTION
Reads the list of AZDO API endpoints used by this module. The list is maintained within the module's root
directory for now - {moduleRoot}\azdoapi.json
#>
function Read-AzdoApiList{
  [cmdletbinding()]
  param(
  
  )
      Write-Debug ("Entered function {0}..." -f $MyInvocation.InvocationName)
  
      # read the json location from the module manifest file and validate it exists
      $manifestData = Import-PowerShellDataFile -Path ("{0}\{1}.psd1" -f $script:moduleRoot, $script:moduleName)
      $apiList = (($manifestData.privatedata.azdoApiList)).replace("{moduleRoot}",$script:moduleRoot)
  
      Write-Debug ("API List location is: $apiList")
  
      if (Test-Path $apiList ){
          
          try{
              # load the API listing
              $apiEndpoints = (Get-Content $apiList -ErrorAction Stop | ConvertFrom-Json -Depth 100)
          }catch{
              $ex = $_
              Write-Error ("Error encountered. Full Error response is `n{0}`n" -f $ex.Exception.Response)
              throw $ex
          }#catch
      }else{
          throw ("Could not find API endpoint file at {0}" -f $apiList) 
      }#if
  
      # return results
      return $apiEndpoints
  }