<#
.SYNOPSIS
Returns all users in an organisation.

.DESCRIPTION
Returns a list of all user accounts in the organisation. Use continuation token in case more values need to return

.PARAMETER organisationName
Name of the Azure DevOps Organisation

.PARAMETER azdoToken
An Azure DevOps access token

.NOTES
API Documentation: https://docs.microsoft.com/en-us/rest/api/azure/devops/graph/users/list?view=azure-devops-rest-6.0&tabs=HTTP
Basic Invocation: GET https://vssps.dev.azure.com/{organization}/_apis/graph/users?subjectTypes={subjectTypes}&continuationToken={continuationToken}&scopeDescriptor={scopeDescriptor}&api-version=6.0-preview.1

extra info on continuation tokens here: https://jessehouwing.net/azure-devops-accessing-apis-with-large-volumes-of-data/

#>
function Get-AzdoUserList{
    [cmdletbinding()]
    param(
        [parameter(Mandatory=$false)]
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
        $apiUri = (Read-AzdoApiList -ErrorAction Stop | Select-Object -ExpandProperty users).list
    }catch{
        $ex = $_
        Write-Error ("Error encountered. Full Error response is `n{0}`n" -f $ex.Exception.Response)
        throw $ex
    }#try

    # swap out the org-specific values in the URI
    $apiUri = ((($apiUri).replace('{organization}',$organisationName)).replace('{project}',$project)).Replace('{repositoryId}',$repository)

    # this call may have a continuation token coming back - create a list to keep adding to it
    $resultsList = [System.Collections.Generic.list[object]]::new()

    Write-Debug ("Calling Invoke-AzdoAPI with:`n")
    Write-Debug ("apiUri: [{0}]" -f $apiUri)

    do{
        try{
            $result = Invoke-AzdoApi -Uri $apiUri `
                                        -Method GET `
                                        -azdoToken $azdoToken `
                                        -authType $authType `
                                        -includeResponseHeaders
                            
        }catch{
            $ex = $_
            Write-Error ("Error encountered. Full Error response is `n{0}`n" -f $ex.Exception.Response)
            throw $ex
        }#try
        
        # extract each of the values in the response into the collection (otherwise you're only left with 1 record in the collection, making it hard to enumarate)
        $result.content.value.foreach({
            $resultsList.add($_)
        })

        if ($result.headers["x-ms-continuationtoken"]){
            Write-Debug ("Continuation Token Detected: {0}" -f $result.headers["x-ms-continuationtoken"])
            # add the continuation token parameter to the apiUri string
            $continuation = $result.headers["x-ms-continuationtoken"]

            $apiUri = ('{0}&continuationtoken={1}' -f $apiUri,$continuation)

        }

    } while ($result.headers["x-ms-continuationtoken"])

    Write-Debug ("Returning results...")
    return $resultsList
}