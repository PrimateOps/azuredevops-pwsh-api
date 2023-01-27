<#
.SYNOPSIS
Adds a member to a team.

.DESCRIPTION
Here we are using the Graph/Users/Create API, with the group descriptors query parameter that 
represents the descriptor of the Team. The API sends a payload to AZDO to load the user(s) in to the
team. 

.PARAMETER organisationName
Name of the Azdo Organisation (not the full URL)

.PARAMETER groupDescriptor
Name of the group the user is to be added to

.PARAMETER userPrincipalName
User to be added to the group - represented in the principleName format from AAD.

.NOTES
In order to get to the descriptor for the group you'll need to look up the  group details from
the group list (call Get-AzdoGroups) - descriptor is an object property.

This call will need to load up the existing list of Azdo Users to ensure the incoming record is a member
of the organisation (api will not error out if the account doesn't exist)

Additional documentation for this API call

API Documentation: https://docs.microsoft.com/en-us/rest/api/azure/devops/graph/users/create?view=azure-devops-rest-6.0&tabs=HTTP

POST https://vssps.dev.azure.com/{organization}/_apis/graph/users?groupDescriptors={groupDescriptors}&api-version=6.0-preview.1

Params Needed:
GroupName (Translated to descriptor at runtime)
MemberName (Translated to originId at runtime) - best to make this a String Array and loop in

Example API call:
https://vssps.dev.azure.com/azdoconfigdev/_apis/Graph/Users?groupDescriptors=vssgp.Uy0xLTktMTU1MTM3NDI0NS01MDc4MDUxNzAtMTQyOTg0ODY0NS0yMTk3MjA4MjUyLTIyNzMzNzA3ODgtMS0yMTA4MTMxNTMzLTY5MTgzNTQ2NS0yMTU3MTk0ODU2LTE1MDE5NTU3NDc

Payload:
{
  "storageKey": "",
  "principalName": "b950f59d-6ee4-4cc1-9b55-2f0e10bbc8ce",
  "origin": "aad"
}
#>
function Add-AzdoGroupMember{
    [cmdletbinding()]
    param(
        [parameter(Mandatory=$false)]
        [string]$organisationName,
        [parameter(Mandatory)]
        [string]$groupDescriptor,
        [parameter(Mandatory)]
        [string]$userPrincipalName,
        [parameter(mandatory=$false)]   
        [string]$azdoToken,
        [parameter(Mandatory=$false)]
        [ValidateSet('Basic','Bearer')]
        [string]$authType = 'Basic',
        [parameter(Mandatory=$false)]
        [switch]$includeResponseHeaders
    )

    $functionName = $MyInvocation.InvocationName
    Write-Debug ("Entered function {0}..." -f $functionName)

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
        $apiUri = (Read-AzdoApiList -ErrorAction Stop | Select-Object -ExpandProperty users).add
    }catch{
        $ex = $_
        Write-Error ("Error encountered. Full Error response is `n{0}`n" -f $ex.Exception.Response)
        throw $ex
    }#try

    # swap out the org-specific values in the URI
    $apiUri = ($apiUri.replace('{organization}',$organisationName)).replace('{groupDescriptors}',$groupDescriptor)

    # set up payload
    $payload = @{
        storageKey = ''
        principalName = $userPrincipalName
        origin = 'aad'
    } | ConvertTo-Json
    
    Write-Debug ("Calling Invoke-AzdoAPI with:`n")
    Write-Debug ("apiUri: [{0}]" -f $apiUri)
    Write-Debug ("Body: `n{0}" -f $payload)

    try{
        $result = Invoke-AzdoApi -Uri $apiUri `
                                -Method POST `
                                -azdoToken $azdoToken `
                                -requestBody $payload `
                                -authType $authType `
                                -ErrorAction Stop
    }catch{
        $ex = $_
        Write-Error ("Error encountered. Full Error response is `n{0}`n" -f $ex.Exception.Response)
        throw $ex
    }#try

    
    return $result
}