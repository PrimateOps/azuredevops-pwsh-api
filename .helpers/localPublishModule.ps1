<#
.DESCRIPTION
This script will do the initial processing of the module .\{modulename} directory (where the module logic is stored) so the 
module can be published. This includes copying the logic to a temporary location where the version can be set before
eventually being published. The package step, if invoked for local developement, will also publish the module to the 
users psmodule path for local testing.

Steps:

Copy .\src to temp location 
Set version in the module manifest (handled by .\setModuleVersion.ps1, with version set by GitVer in the pipeline)
Copy module to user's psmodule path directory with the version as the subfolder.

.PARAMETER ModuleSource
Mandatory - location of the Module source files

.PARAMETER version
Optional - set the version of the package to deploy. Defaults to value in psd1 if not included.

.PARAMETER OutputPath
Mandatory value - location to publish the module to for testing purposes.

.PARAMETER ModuleName
Mandatory value used to determine the psd1 file. 

#>
param(
    [Parameter(Mandatory)]
    [String]$ModuleSource,
    [Parameter(Mandatory)]
    [String]$OutputPath
)
    # use convention to determine the module name (it's the name of the repository, and folder name)
    $ModuleName = (Split-Path -Path $ModuleSource -Leaf)

    # check target path
    if (Test-Path $OutputPath){
        try{
            Write-Host ('[{0}] directory already exists. Attempting cleanup...' -f $OutputPath)
            Remove-Item -Path $OutputPath -Recurse -Force -ErrorAction Stop
        }catch{
            $ex = $_

            Write-Error ('Failed to clean up directory [{0}]. Error follows.' -f $OutputPath)
            throw $ex
        }#try
    }else{
        # otherwise, create directory
        try{
            Write-Host ('Attempting to create build output [{0}]...' -f $OutputPath)
            New-Item -Path $OutputPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
        }catch{
            $ex = $_

            Write-Error ('Failed to create directory [{0}]. Error follows.' -f $OutputPath)
            throw $ex
        }#try
    }#if

    # copy module to temp directory
    Write-Host ('Copying module content to [{0}]' -f $OutputPath)

    try{
        Copy-Item -Path $ModuleSource -Destination $OutputPath -Force -Recurse -ErrorAction Stop
    }catch{

        $ex = $_

        Write-Error ('Failed to copy module to build directory [{0}]. Error follows.' -f $OutputPath)
        throw $ex
    }#try/catch


