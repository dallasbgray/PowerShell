<#
.SYNOPSIS
    .Prepends a formatted date to the beginning of image file names
.DESCRIPTION
    .Runs Get-ChildItem on the provided path and filters Where-Object file extensions are certain image types. Then attempts to use the Windows Shell COM object to access the Date Taken property that isn't directly accessible through .NET's System.IO classes. If this date is found, it then formats & prepends that to the beginning of the image filename
.PARAMETER FolderPath
    Specifies a path to the folder of images to rename
.EXAMPLE
    PS C:\> .\RenameImagesWithDate.ps1 -FolderPath C:\Path-To-Photos-Here\photos -Verbose
.NOTES
    Author: Dallas Gray
    Date:   August 8th, 2024
#>
Function RenameImagesWithDate {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$true)]
		[ValidateScriptAttribute({
			Test-Path -Path $_
		},
		ErrorMessage = "'{0}' is not a valid directory")]
		[string]$FolderPath
	)

	Write-Host "Script begun..."
	$countModified = 0
	$countSkipped = 0
	$countErrored = 0

	Get-ChildItem $FolderPath `
	| Where-Object { $_.extension -in '.jpg', '.jpeg' } `
	| ForEach-Object {
		try {
			$DateFormat = 'yyyy-MM-dd'
			$DateTakenWinApi = 12
			# $DateCreatedWinApi = 4

			if ($null -eq $Shell) {
				$Shell = New-Object -ComObject shell.application
			}
	 
			$dir = $Shell.Namespace($_.DirectoryName)

			$DateTakenString = $dir.GetDetailsOf($dir.ParseName($_.Name), $DateTakenWinApi)
			if ($DateTakenString -eq '') {
				# can also use DateCreated as a substitute for DateTaken
				# $DateTakenString = $dir.GetDetailsOf($dir.ParseName($_.Name), $DateCreatedWinApi)
				$countSkipped++
				continue
			}
		
			# sanitze string
			$DateTakenString = $DateTakenString -replace '[^0-9AaPpMm\.\:\ \/]', ''
			# parse to DateTime
			$DateTaken = Get-Date $DateTakenString

			$currentFileName = $_.Name
			$newFileName = $DateTaken.ToString($DateFormat) + "_" + $_.Name
		
			Rename-Item -Path $_.FullName -NewName $newFileName #-WhatIf -Confirm
			$countModified++

			Write-Verbose "Renamed file $currentFileName to $newFileName"
		}
		catch {
			$countErrored++
			Write-Error "an error occurred:"
			Write-Error "$_"
		}
	}

	# colored output
	Write-Host "`n	Script Finished Successfully	`n" -BackgroundColor Green
	Write-Host "Modified " -NoNewline
	Write-Host $countModified -ForegroundColor Blue -NoNewline
	Write-Host " files, skipped " -NoNewline
	Write-Host $countSkipped -ForegroundColor Yellow -NoNewline
	Write-Host " eligible files, and " -NoNewline
	Write-Host $countErrored -ForegroundColor Red -NoNewline
	Write-Host " files had errors."
}