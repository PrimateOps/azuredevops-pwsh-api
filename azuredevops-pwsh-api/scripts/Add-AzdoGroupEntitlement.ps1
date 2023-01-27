function Add-AzdoGroupEntitlement{
    [cmdletbinding()]
    param(
        [parameter(mandatory=$false)]
        [string]$organisationName,
        [parameter(Mandatory)]
        [string]$groupDisplayName,
        [parameter(Mandatory)]
        [string]$groupId,
        [parameter(Mandatory)]
        [string]$licenceMapping,
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
    try{
        $apiUri = (Read-AzdoApiList -ErrorAction Stop | Select-Object -ExpandProperty groupEntitlements).add
    }catch{
        $ex = $_
        Write-Error ("Error encountered. Full Error response is `n{0}`n" -f $ex.Exception.Response)
        throw $ex
    }#try

    # swap out the org-specific values in the URI
    $apiUri = $apiUri.replace('{organization}',$organisationName)

    $requestBody = @{
        group = @{
            origin = "AAD"
            displayName = $groupDisplayName
            originId = $groupId
            subjectKind = "group"
        }
        id = $null
        licenseRule = @{
            licensingSource = "account"
            accountLicenseType =  $licenceMapping
        }
    }

    # convert payload
    $jsonPayload = $requestBody | ConvertTo-Json -Depth 50
    Write-Debug ("[DEBUG]Request body for {0} `n {1}" -f $groupDisplayName, $jsonPayload)

    Write-Host ("Applying Group rule... {0} mapping to {1} license type..." -f $groupDisplayName, $licenceMapping)

    Write-Debug ("Calling Invoke-AzdoAPI with:`n")
        Write-Debug ("apiUri: [{0}]" -f $apiUri)
        Write-Debug ("Body: `n{0}" -f $jsonPayload)
    try{
        $result = Invoke-AzdoApi -Uri $apiUri `
                                 -Method POST `
                                 -azdoToken $azdoToken `
                                 -requestBody $jsonPayload `
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