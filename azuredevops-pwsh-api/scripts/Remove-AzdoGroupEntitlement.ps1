<#
.PARAMETER groupId

Mandatory. Ths is the id value of the group object in Azure DevOps - NOT the object id of the AAD 
group. The way to source this id is to run Get-AzdoGroupEntitlements (id of group object).

.PARAMETER removeGroupMemberships

Defaults to false. Optional parameter that specifies whether the group with the given ID 
should be removed from all other groups

.PARAMETER whatIf
Defaults to false. specifies if the rules defined in group entitlement should be deleted and the 
changes are applied to it’s members (default option) or just be tested
#>
function Remove-AzdoGroupEntitlement{
    [cmdletbinding()]
    param(
        [parameter(mandatory=$false)]
        [string]$organisationName,
        [parameter(Mandatory)]
        [string]$azdoGroupId,
        [parameter(Mandatory=$false)]
        [switch]$removeGroupMembership,
        [parameter(Mandatory=$false)]
        [switch]$whatIf,
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

    # we need to make an additional azdo call here to get the azdo group id from the backend (i.e. the )

    # set the whatIf value to either 0 or 1 (apply vs test)
    if ($whatIf){
        $ruleOption = 1
        Write-Host ("Running in WhatIf mode. Deletion won't take place.") -ForegroundColor Yellow
    }else {
        $ruleOption = 0
        Write-Host ("Running in apply mode! Group Rule WILL be deleted.") -ForegroundColor Red
    }

    # import api URI details for this call
    try{
        $apiUri = (Read-AzdoApiList -ErrorAction Stop | Select-Object -ExpandProperty groupEntitlements).delete
    }catch{
        $ex = $_
        Write-Error ("Error encountered. Full Error response is `n{0}`n" -f $ex.Exception.Response)
        throw $ex
    }#try

    # swap out the org-specific values in the URI
    $apiUri = ((($apiUri).replace('{organization}',$organisationName)).replace('{groupId}',$groupId).replace('{ruleOption}',$ruleOption)).replace('{removeGroupMembership}',$removeGroupMembership)    
    Write-Host ("Running remove of groupId {0}... Remove from all other groups set to {1}" -f $groupID, $removeGroupMembership)
    
    try{
        Write-Debug ("Calling Invoke-AzdoAPI with:`n")
        Write-Debug ("apiUri: [{0}]" -f $apiUri)

        $result = Invoke-AzdoApi -Uri $apiUri `
                                 -Method DELETE `
                                 -azdoToken $azdoToken `
                                 -authType $authType `
                                 -includeResponseHeaders:$includeResponseHeaders
    }catch{
        $ex = $_
        Write-Error ("Error encountered. Full Error response is `n{0}`n" -f $ex.Exception.Response)
        throw $ex
    }#try

    Write-Debug ("Exiting function {0}..." -f $MyInvocation.InvocationName)

    return $result
}