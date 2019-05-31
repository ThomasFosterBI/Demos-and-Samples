# Parameters - fill these in before running the script!
# =====================================================

$FilePath = ""    # The path of the pbix file you are changing
$TempPath = "C:\Temp"   # Temp location for file storage
$NewFileName = "" # New name for edited pbix file
$NewBackgroundPath = "" # File path of the new background image as a png

# ======================================================

# Clear Temp
Get-ChildItem -Path $TempPath -Recurse | Foreach-object {Remove-item -Recurse -path $_.FullName }
# Remove items with special characters in names that will be missed by remove-item
$CleanFiles = Get-ChildItem -Path $TempPath -Recurse | Select-Object FullName,@{name='CleanName';expression= {[Management.Automation.WildcardPattern]::Escape($_.FullName)}}
$CleanFiles | Foreach-object {Remove-item -Recurse -Force -path $_.CleanName }

# Copy file to temp
Copy-Item -Path $FilePath -Destination $TempPath

#Rename copied file to .zip
$FileName = ((Get-ChildItem $TempPath -Filter *.pbix).Name)
$ZipName = $FileName -replace ".pbix",".zip"
Rename-Item -Path "$($TempPath)\$($FileName)" -NewName $ZipName 

# Expand ZIP Archive
Expand-Archive -Path "$($TempPath)\$($ZipName)" -DestinationPath "$($TempPath)"
Remove-Item -Path "$($TempPath)\$($ZipName)"

# Get Backgrounds in file
$Backgrounds = (Get-ChildItem -Path "$($TempPath)\Report\StaticResources\RegisteredResources\Background*").Name

# Replace Backgrounds
foreach ($i in $Backgrounds) {
    Remove-Item -Path "$($TempPath)\Report\StaticResources\RegisteredResources\$($i)"
    Copy-Item -Path $NewBackgroundPath -Destination "$($TempPath)\Report\StaticResources\RegisteredResources\$($i)"
}

# Recompress archive
$StartPath = $FilePath.Replace($FileName,"")

if (-not (test-path "$env:ProgramFiles\7-Zip\7z.exe")) 
    {
        throw "$env:ProgramFiles\7-Zip\7z.exe needed"
} 
set-alias sz "$env:ProgramFiles\7-Zip\7z.exe"  

$Source = "$($TempPath)\*"
$Target = "$($StartPath)$($NewFileName).zip"
sz a -mx=9 $Target $Source
try {Rename-Item -Path $Target -NewName "$($NewFileName).pbix"}
catch {Rename-Item -Path $Target -NewName "$($NewFileName) - 2.pbix"}

# Clear Temp
Get-ChildItem -Path $TempPath -Recurse | Foreach-object {Remove-item -Recurse -path $_.FullName }
# Remove items with special characters in names that will be missed by remove-item
$CleanFiles = Get-ChildItem -Path $TempPath -Recurse | Select-Object FullName,@{name='CleanName';expression= {[Management.Automation.WildcardPattern]::Escape($_.FullName)}}
$CleanFiles | Foreach-object {Remove-item -Recurse -Force -path $_.CleanName }

