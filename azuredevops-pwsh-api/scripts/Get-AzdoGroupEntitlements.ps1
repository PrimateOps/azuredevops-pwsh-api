<#
.Notes
Calls the _list_ method of the API as a way of returning the whole list. This function can be 
expanded in the future to be more targeted for individual AAD groups (if need be). 
#>
function Get-AzdoGroupEntitlements{
    [cmdletbinding()]
    param(
        [parameter(mandatory=$false)]
        [string]$organisationName,
        [parameter(mandatory=$false)]   
        [string]$azdoToken,
        [parameter(Mandatory=$false)]
        [ValidateSet('Basic','Bearer')]
        [string]$authType = 'Basic',
        [parameter(Mandatory=$false)]
        [switch]$includeResponseHeaders
    )

    Write-Debug ("Entered function {0}..." -f $MyInvocation.InvocationName)

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
    Write-Debug ("Calling Invoke-AzdoAPI with:`n")
    Write-Debug ("apiUri: [{0}]" -f $apiUri)
    try{
        $apiUri = (Read-AzdoApiList -ErrorAction Stop | Select-Object -ExpandProperty groupEntitlements).list
    }catch{
        $ex = $_
        Write-Error ("Error encountered. Full Error response is `n{0}`n" -f $ex.Exception.Response)
        throw $ex
    }#try

    # swap out the org-specific values in the URI
    $apiUri = $apiUri.replace('{organization}',$organisationName)

    try{
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

    Write-Debug ("Exiting function {0}..." -f $MyInvocation.InvocationName)

    return $result.value
}