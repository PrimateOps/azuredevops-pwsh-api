<#
.SYNOPSIS
Resolves an ID into a descriptor (needed for most graph operations in Azure DevOps)

.DESCRIPTION
Resolves an ID into a descriptor (needed for most graph operations in Azure DevOps). One use case 
in particular is getting access to a particular project's descriptor - the Projects API only returns
an id as a unique identifier, but the ability to add resources (users/groups) to a project requires the 
handle to that project's descriptor... Use this cmdlet to get that.

.PARAMETER objectUUID
The object's UUID (usually represented in as an id property). To source it, you may need to make a call 
to a different API first.

.NOTES

API Doco: https://docs.microsoft.com/en-us/rest/api/azure/devops/graph/descriptors/get?view=azure-devops-rest-6.0&tabs=HTTP

Simple usage:
GET https://vssps.dev.azure.com/{organization}/_apis/graph/descriptors/{storageKey}?api-version=6.0-preview.1

#>
function Get-AzdoDescriptor{
    [cmdletbinding()]
    param(
        [parameter(Mandatory=$false)]
        [string]$organisationName,
        [parameter(Mandatory)]
        [string]$objectUUID,
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

    try{
        $apiUri = (Read-AzdoApiList -ErrorAction Stop | Select-Object -ExpandProperty descriptors).get
    }catch{
        $ex = $_
        Write-Error ("Error encountered. Full Error response is `n{0}`n" -f $ex.Exception.Response)
        throw $ex
    }#try

    # swap out the org-specific values in the URI
    $apiUri = ((($apiUri).replace('{organization}',$organisationName)).replace('{storageKey}',$objectUUID))

    try{
        # import api URI details for this call
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