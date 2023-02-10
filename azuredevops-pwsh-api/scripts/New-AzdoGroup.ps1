<#
.SYNOPSIS
Create an Azure DevOps Group

.DESCRIPTION
Creates an Azure DevOps Group. 

Adding a Project Scoped Group:
Requires a scope descriptor to add a project-scoped group. By omitting
the descriptor, the group will be created at the organisational scope.

Adding the group to another group:
Requires the 'Project Descriptor' as a comma separated value included in the query string.

See Notes section for documentation

.PARAMETER groupName
Name of the group you wish to add.

.PARAMETER groupDescription
Description of the group are adding.

.PARAMETER projectName
Optional - include if the group is to be added within a project. If omitted, the group will be 
added at the collection scope (i.e. a collection-level group).

.NOTES
Usage:
Getting the accurate descriptors is the most important part:

Scope Descriptor (only needed when adding group to a project project):
Use Get-AzdoProject (using project name as the var)
Use the Project Id that's returned and use it in Get-AzdoDescriptor to get the descriptor

Include descriptor value in the query string.

Documentation:
https://docs.microsoft.com/en-us/rest/api/azure/devops/graph/groups/create?view=azure-devops-rest-6.0&tabs=HTTP

Adding Group:
API Uri string (Collection Scope):
https://vssps.dev.azure.com/azdoconfigdev/_apis/Graph/Groups
Payload (creating new group):
{
  "displayName": "testg",
  "description": "",
  "storageKey": "",
  "crossProject": false,
  "descriptor": "",
  "restrictedVisibility": false,
  "specialGroupType": "Generic"
}
API Uri string (Project Scope):
https://vssps.dev.azure.com/azdoconfigdev/_apis/Graph/Groups?scopeDescriptor=scp.ZjI3ZDQ0MWUtMzk1NS00NWMyLTgyZjYtYmNiYzg3ODBlMmE0
Payload (creating a new group):
{
  "displayName": "AGroup",
  "description": "Testing Testing",
  "storageKey": "",
  "crossProject": false,
  "descriptor": "",
  "restrictedVisibility": false,
  "specialGroupType": "Generic"
}
#>
function New-AzdoGroup{
  [cmdletbinding()]
    param(
        [parameter(Mandatory=$false)]
        [string]$organisationName,
        [parameter(Mandatory)]
        [string]$groupName,
        [parameter(Mandatory=$false)]
        [string]$groupDescription,
        [parameter(Mandatory=$false)]
        [string]$projectName,
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
        $apiUri = (Read-AzdoApiList -ErrorAction Stop | Select-Object -ExpandProperty groups).create
    }catch{
        $ex = $_
        Write-Error ("Error encountered. Full Error response is `n{0}`n" -f $ex.Exception.Response)
        throw $ex
    }#try

    # swap out the org-specific values in the URI
    $apiUri = $apiUri.replace('{organization}',$organisationName)

    # set up the payload (same irrespective of scope)
    $payload = @{
        displayName = $groupName
        description = (([string]::IsNullOrWhiteSpace($groupDescription)) ? [string]::Empty : $groupDescription)
    } | ConvertTo-Json

    # check if project group is to be added at project scope
    if (-not([string]::IsNullOrEmpty($projectName))){
        # call Get-AzdoProject
        try{
            $projDetails = Get-AzdoProject -organisationName $organisationName `
                                            -projectName $projectName `
                                            -azdoToken $azdoToken `
                                            -authType $authType `
                                            -ErrorAction Stop

            Write-Debug ("Project Details returned: `n{0}" -f ($projDetails | Out-String))
        }catch{
            $ex = $_
            Write-Error ("Could not retrive details for project [{0}]. Exception: {1}`n" -f $projectName,$ex.Exception.Message)
            throw $ex
        }

        try{
            # get the descriptor by using the project name
            $projDescriptor = Get-AzdoDescriptor -organisationName $organisationName `
                                                    -objectUUID $projDetails.id `
                                                    -azdoToken $azdoToken `
                                                    -authType $authType `
                                                    -ErrorAction Stop
            Write-Debug ("Project Descriptor returned: {0}" -f $projDescriptor.value)
        }catch{
            $ex = $_
            Write-Error ("Could not retrieve descriptor value for project [{0}], Project Id [{1}]. Exception: `n" -f $projDetails.Name, $projDetails.id)
            throw $ex
        }

        # now add the descriptor to the api query string
        $apiUri = ("{0}&scopeDescriptor={1}" -f $apiUri,$projDescriptor.value)
    }#if

    Write-Debug ("Calling Invoke-AzdoAPI with:`n")
    Write-Debug ("apiUri: [{0}]" -f $apiUri)
    Write-Debug ("Body: `n{0}" -f $payload)

    try{
        $result = Invoke-AzdoApi -Uri $apiUri `
                                -Method POST `
                                -azdoToken $azdoToken `
                                -requestBody $payload `
                                -authType $authType `
                                -includeResponseHeaders:$includeResponseHeaders
                        
    }catch{
        $ex = $_
        Write-Error ("Error encountered. Full Error response is `n{0}`n" -f $ex.Exception.Response)
        throw $ex
    }#try

    return $result
}