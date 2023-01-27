<#
.SYNOPSIS
Returns information about a Git repository

.DESCRIPTION
Returns information about a Git repository in a given project. Only works with Git repositories

.PARAMETER organisationName
Name of the Azure DevOps Organisation

.PARAMETER project
Name or ID of the project which hosts the repository.

.PARAMETER repository
Name or ID of the repository.

.PARAMETER azdoToken
#>
function Get-AzdoRepository{
[cmdletbinding()]
param(
    [parameter(Mandatory=$false)]
    [string]$organisationName,
    [parameter(Mandatory)]
    [string]$project,
    [parameter(Mandatory)]
    [string]$repository,
    [parameter(mandatory=$false)]   
    [string]$azdoToken,
    [parameter(Mandatory=$false)]
    [ValidateSet('Basic','Bearer')]
    [string]$authType = 'Basic',
    [parameter(Mandatory=$false)]
    [switch]$includeResponseHeaders
)
    
    Write-Debug ("Entered function {0}..." -f $MyInvocation.InvocationName)
    # check for token
    if ([string]::isnullorempty($azdoToken)){
        # look for the PAT env variable. If it's present, we're good to go
        if ([string]::isnullorempty($env:AZDO_PERSONAL_ACCESS_TOKEN)){
            throw 'You must supply an access token for your AzDO organisation. Either supply the parameter, or set $env:AZDO_PERSONAL_ACCESS_TOKEN'
        }else{
            $azdoToken = $env:AZDO_PERSONAL_ACCESS_TOKEN
        }
    }

    # check for organisation
    if ([string]::isnullorempty($organisationName)){
        # look for env variable
        if ([string]::isnullorempty($env:AZDO_ORGANISATION)){
            throw 'You must supply a value for the AzDO organisation. Either supply the parameter, or set $env:AZDO_ORGANISATION'
        }else{
            $organisationName = $env:AZDO_ORGANISATION
        }
    }


    # import api URI details for this call
    try{
        $apiUri = (Read-AzdoApiList -ErrorAction Stop | Select-Object -ExpandProperty repositories).get
    }catch{
        $ex = $_
        Write-Error ("Error encountered. Full Error response is `n{0}`n" -f $ex.Exception.Response)
        throw $ex
    }#try

    # swap out the org-specific values in the URI
    $apiUri = ((($apiUri).replace('{organization}',$organisationName)).replace('{project}',$project)).Replace('{repositoryId}',$repository)

    try{
        Write-Debug ("Calling Invoke-AzdoAPI with:`n")
        Write-Debug ("apiUri: [{0}]" -f $apiUri)
        
        $result = Invoke-AzdoApi -Uri $apiUri `
                                    -Method GET `
                                    -azdoToken $azdoToken `
                                    -authType $authType `
                                    -includeResponseHeaders:$includeResponseHeaders
                        
    }catch{
        $ex = $_
        Write-Error ("Error encountered. Full Error response is `n{0}`n" -f $ex.Exception.Response)
        throw $ex
    }#try

    return $result
}