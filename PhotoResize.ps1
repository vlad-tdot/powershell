# Script written by vlad
# github.com/vlad-tdot
# This script is BSD licensed
# This script will go through a folder tree and resize every JPG image. 
# Resized images will be placed into target directory, with original folder tree replicated
# Usage: PhotoResize.ps1 -OriginalPath <PathToOriginals> -NewPath <PathWhereToPlaceResizedImages>
# Prerequisites: ImageMagick, with magick.exe in your path

[CmdletBinding()]
param (
    [Parameter(Mandatory=$True,
    HelpMessage='Please specify path to folder with originals')]
    [ValidateNotNull()]
    [string]
    $OriginalPath,

    [Parameter(Mandatory=$True,HelpMessage='Please specify target path')]
    [ValidateNotNull()]
    [string]
    $NewPath

)

If ($OriginalPath -eq $NewPath) {
    throw 'Cannot copy to the same path'
}

if (-not (Get-Command magick.exe)) {
    throw 'Cannot find ImageMagick magick.exe. Is it installed and in your path?'
}


function iteratedir {
    param([string]$Path)
    $files = Get-ChildItem $Path
    foreach ($item in $files) {
        #write-host $item
        # If source item is directory
        if (Test-Path -Path $item.FullName -PathType Container) {
            # If it doesn't exist at destination
            if (-not (Test-Path $item.FullName.Replace($OriginalPath, $NewPath))) {
                # Create folder at destination
                mkdir $item.FullName.Replace($OriginalPath, $NewPath)
            }
            # Since it's a folder - dive into it and iterate
            iteratedir -Path $item.FullName
          # If it's not a directory
        } else {
            # If item is a jpg
            if ($item.Extension -like ".jpg") {
                # Compose new filename
                $newFileName = $item.FullName.Replace($OriginalPath, $NewPath)
                # If destination doesn't exist
                If (-not (Test-Path $newFileName)) {
                    write-host "Converting" $item.FullName "to" $newFileName
                    magick.exe $item.FullName -resize 1080x1080^ $newFileName
                } else {
                    # But if destination image already exists - skip conversion
                    Write-Host "File" $newFileName "already exists, skipping" 
                }
            }
        }
    }
}

iteratedir -Path $OriginalPath
