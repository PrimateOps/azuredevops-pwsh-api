<#
.SYNOPSIS
Returns information on a given project. Use -ListAll to get all projects in an organisation.

.DESCRIPTION
Returns information on a given project. Use -ListAll to get all projects in an organisation.

.PARAMETER projectName
Name of the project. Mandatory when invoked as SingleProject parameter set.

.PARAMETER listAll
Switch parameter to return a list of all projects in the organisation.

.NOTES

API Doco: 
Get: https://docs.microsoft.com/en-us/rest/api/azure/devops/core/projects/get?view=azure-devops-rest-6.0
List: https://docs.microsoft.com/en-us/rest/api/azure/devops/core/projects/list?view=azure-devops-rest-6.0&tabs=HTTP

Invoke API GET:
GET https://dev.azure.com/{organization}/_apis/projects/{projectId}?api-version=6.0

Invoke API LIST: 
GET https://dev.azure.com/{organization}/_apis/projects?api-version=6.0

#>
function Get-AzdoProject{
[cmdletbinding()]
param(
    [parameter(mandatory=$false)]
    [string]$organisationName,
    [parameter(Mandatory,ParameterSetName="getProjectByName")]
    [string]$projectName,
    [parameter(Mandatory,ParameterSetName="listAllProjects")]
    [switch]$listAll,
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
        if ($PSCmdlet.ParameterSetName -eq "getProjectByName"){
            $apiUri = (Read-AzdoApiList -ErrorAction Stop | Select-Object -ExpandProperty projects).get
        }else{
            $apiUri = (Read-AzdoApiList -ErrorAction Stop | Select-Object -ExpandProperty projects).list
        }
    }catch{
        $ex = $_
        Write-Error ("Error encountered. Full Error response is `n{0}`n" -f $ex.Exception.Response)
        throw $ex
    }#try

    # swap out the org-specific values in the URI
    $apiUri = $apiUri.replace('{organization}',$organisationName).replace('{projectId}',$projectName)

    Write-Debug ("Calling Invoke-AzdoAPI with:`n")
    Write-Debug ("apiUri: [{0}]" -f $apiUri)
    
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

    return $result
    
}