<#
.SYNOPSIS
        Provide a method by which Microsoft Store apps can be loaded recursively without the use of JSON, XML, or any other type of configuration file.

.DESCRIPTION

        This script will traverse the path provided in the $HSAStore variable for telltale filetypes, then use the DISM-based built-in PowerShell modules to install them.

.PARAMETER HSAStore
        
        Path to folder containing one, more, or all of the Store file types

.PARAMETER Provision
        
        Flag, either True or False, about whether the app is provisioned for the computer as a provisioning AppX, or for users.

.PARAMETER LogFile

        Location to the path where the PSTranscript will be dumped. Default is the current directory.


.NOTES

    FileName: Import-HSAStore.ps1
    Author:   Graham Foral
    Created:  9/18/2022
#>

param(

    $HSAStore,
    $Provision,
    $LogFile = "AddHSAStore" + (Get-Date -Format yyyy-MM-dd_HHmmss) + ".log"

)

$PackageDir = Get-ChildItem -Path $HSAStore -Directory -Recurse
Clear
Start-Transcript -Path $LogFile
ForEach ($Package in $PackageDir) {
    If ((Get-ChildItem -Path $Package.FullName -File).count -lt 1) {
        Write-Host "Warning: $($Package.Name) will be ignored because it contains no files. Subdirectories will be searched..." -ForegroundColor Yellow 
        Continue
    }
    else {
    
        Write-Host "Information: $($Package.FullName)" -ForegroundColor Green 

        $HSA = Get-ChildItem -Path $Package.FullName -ErrorAction SilentlyContinue | Where-Object { ($_.Name -like "*.msix*") -or ($_.Name -like "*.*appxbundle") -or ($_.Name -like "*.*appx") -and ($_.Name -notlike "*Microsoft*") }
        $Dependencies = Get-ChildItem -Path $Package.FullName -Filter "*Microsoft*" -ErrorAction SilentlyContinue
        $License = Get-ChildItem -Path $Package.FullName -Filter "*.xml" -ErrorAction SilentlyContinue
    
        Write-Host "Package Content:"
        Write-Host "- HSA: $($HSA.Name)"
        Write-Host "- Dependencies: ";
            $i = 1 
            ForEach($Dependency in $Dependencies) {
                Write-Host "   $i - $($Dependency.Name)"
                $i = $i + 1
            }
        Write-Host "- License: $($License.Name)"
        Write-Host "`n"
    
        If ($Provision -eq "True") {
            If ($License) {
                
                Add-AppxProvisionedPackage -Online -PackagePath $HSA.FullName -LicensePath $License.FullName -DependencyPackagePath $Dependencies.FullName -Regions All
            }
            else {
                
                Add-AppxProvisionedPackage -Online -PackagePath $HSA.FullName -SkipLicense -DependencyPackagePath $Dependencies.FullName -Regions All
            }
         
        }
        else {
            If ($Dependencies) {
                Add-AppxPackage -Path $HSA.FullName -DependencyPath $Dependencies.FullName 
            }
            else {
                Add-AppxPackage -Path $HSA.FullName
            }
        }
    }
}
Stop-Transcript  
