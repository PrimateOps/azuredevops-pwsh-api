<#
.SYNOPSIS
Internal module function to standardise the Azure DevOps REST API call.

.DESCRIPTION
Internal function that standardises the Azure DevOps REST API call. This function abstracts the internal mechanism of
calling the AZDO api, including the determination of the calling context - when called within a pipeline, a bearer token
is passed compared to a basic PAT token when invoked from a standard user session.

Abstracting the API call into a single function has the added benefits of reducing duplicated logic in every function
that calls the API, and provides an easy mechanism to mock AZDO API responses when unit testing individual functions.

.PARAMETER Uri

Uri of the API to be called.

.PARAMETER Method
HTTP method to call on the API. Valid inputs are GET,POST,PUT,DELETE,PATCH

.PARAMETER requestBody

Optional parameter, mostly provided with POST/PUT/PATCH operations.

.PARAMETER azdoToken

Token used for the API call.

.PARAMETER authType

Optional. Allows the caller to define the auth mechanism (Basic or Bearer). Defaults to Basic.

.PARAMETER includeResponseHeaders

Optional parameter. Use this switch parameter to indicate if you want the response headers sent back 
from the API. 

.EXAMPLE

$apiUri = "https://vsaex.dev.azure.com/opsmonkey/_apis/groupentitlements?api-version=4.1-preview.1"
$azdoToken = "slkkkn323en423notarealtokensdlajfsdjf"
$requestHeader = @{
        group = @{
            origin = "AAD"
            displayName = "SomeGroup"
            originId = "GroupId"
            subjectKind = "group"
        }
        id = $null
        licenseRule = @{
            licensingSource = "account"
            accountLicenseType =  "Express"
        }
    }

$jsonPayload = $requestHeader | Converttto-Json -Depth 50

Invoke-AzdoApi  -Uri $apiUri `
                -Method POST `
                -azdoToken $azdoToken `
                -requestBody $jsonPayload `
                -authType Basic `
                -includeResponseHeaders
                  
#>
function Invoke-AzdoApi{
[cmdletbinding()]
param(
    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]$uri,
    [parameter(Mandatory)]
    [ValidateSet('GET','POST','PUT','DELETE','PATCH')]
    [String]$method,
    [parameter()]
    [String]$requestBody,
    [parameter(Mandatory)]
    [String]$azdoToken,
    [parameter()]
    [ValidateSet('Basic','Bearer')]
    [string]$authType = 'Basic',
    [parameter()]
    [switch]$includeResponseHeaders
)
    Write-Debug ("Entered function {0}..." -f $MyInvocation.InvocationName)
    
    $invocationParameters = @{
        Uri = $Uri.Replace(' ', '%20')
        ContentType = "application/json"
        Method = $Method
    }

    # determine the authentication mechanism based on input
    Write-Debug ("Authentication Type: {0}" -f $authType)
    $token = $azdoToken | ConvertTo-SecureString -AsPlainText -Force
    if ($authType -eq 'Basic'){
        $invocationParameters.add('Authentication','Basic')
        $cred = [PSCredential]::new('PAT',$token)
        $invocationParameters.Add('Credential',$cred)
    }else{
        # use bearer auth
        $invocationParameters.add('Authentication','Bearer')
        $invocationParameters.Add('Token',$token)
    }#if

    # check if a payload was provided:
    if (-not([string]::isnullorempty($requestBody))){
        # add to the parameters
        $invocationParameters.add('Body',$requestBody)
    }#if

    # check if response headers need to be included
    if ($includeResponseHeaders){
        Write-Debug ("includeResponseHeaders switch included. Creating headers variable to return...")
        # set the responseheadersvariable to 'headers', which we'll return with the result
        $invocationParameters.add('ResponseHeadersVariable','headers')
    }

    Write-Debug ("Request parameters: `n {0}" -f ($invocationParameters | Out-String))
    
    try{
        $response = Invoke-RestMethod @invocationParameters -ErrorAction Stop
    }catch{
        $ex = $_
        Write-Error ("Error encountered. Full Error response is `n{0}`n" -f $ex.Exception.Response)
        throw $ex
    }#try

    if ($includeResponseHeaders){
        Write-Debug ('Returning custom object with response headers...')
        # include the headers in a custom object on the way out.
        $result = [PSCustomObject]@{
            headers = $headers
            content = $response
        }
    }else{
        Write-Debug ('Returning standard API response...')
        $result = $response
    }

    # return out the results    
    return $result
}