<#
.SYNOPSIS
    Prepends a formatted date to the beginning of image file names
.DESCRIPTION
    Runs Get-ChildItem on the provided path and filters Where-Object file extensions are certain image types. Then attempts to use the Windows Shell COM object to access the Date Taken property that isn't directly accessible through .NET's System.IO classes. If this date is found, it then formats & prepends that to the beginning of the image filename
.PARAMETER FolderPath
    Specifies a path to the folder of images to rename
.PARAMETER UseParallel
	***DO NOT USE THIS OPTION! Runs very slowly, runs the ForEach-Objection function with the -Parallel option
.EXAMPLE
    PS C:\> Rename-DatedImages -Verbose -FolderPath C:\Path-To-Photos-Here\photos
.NOTES
    Author: Dallas Gray
    Date:   August 8th, 2024
#>
Function Rename-DatedImages {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$true)]
		[ValidateScript(
			{ Test-Path -Path $_ },
			ErrorMessage = "'{0}' is not a valid directory according to '{1}'")
		]
		[string]$FolderPath,

		[switch]$UseParallel
	)

	Write-Host "`n`n	Renaming Images...`n" -ForegroundColor DarkBlue

	# thread-safe in order to allow the -Parallel option in ForEach-Object
	$threadSafeDictionary = [System.Collections.Concurrent.ConcurrentDictionary[string,int]]::new()
	$threadSafeDictionary.TryAdd("numTotal", 0) > $null # redirect to $null to ignore the return value
	$threadSafeDictionary.TryAdd("numModified", 0) > $null
	$threadSafeDictionary.TryAdd("numSkipped", 0) > $null
	$threadSafeDictionary.TryAdd("numErrored", 0) > $null
 
	# probably a better way to simplify this into one pipeline, but this works for now
	if ($UseParallel) {
		# parallel function
		Write-Host "Warning: Parallel implementation is very slow, recommended to not use this option" -BackgroundColor Red

		Measure-Command {
			Get-ChildItem -Recurse -Depth 5 -Path $FolderPath `
			| Where-Object { $_.extension -in '.jpg', '.jpeg' } `
			| ForEach-Object -Parallel {
				try {
					$dict = $using:threadSafeDictionary
					$dict["numTotal"]++ # this worked, but is it atomic?
	
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
						
						$dict["numSkipped"]++
						return # continue behaves like break in ForEach-Object, use return intead
					}
				
					# sanitze string
					$DateTakenString = $DateTakenString -replace '[^0-9AaPpMm\.\:\ \/]', ''
					# parse to DateTime
					$DateTaken = Get-Date $DateTakenString
	
					$currentFileName = $_.Name
					$newFileName = $DateTaken.ToString($DateFormat) + "_" + $_.Name
				
					Rename-Item -Path $_.FullName -NewName $newFileName #-WhatIf -Confirm
					$dict["numModified"]++
	
					Write-Verbose "Renamed file $currentFileName to $newFileName"
				}
				catch {
					$dict = $using:threadSafeDictionary
					$dict["numErrored"]++
					Write-Error "an error occurred:"
					Write-Error "$_"
				}
			}
		} | Select-Object TotalMilliseconds -OutVariable runtimeMillis
	} else {
		# synchronous function
		Measure-Command {
			Get-ChildItem -Recurse -Depth 3 -Path $FolderPath `
			| Where-Object { $_.extension -in '.jpg', '.jpeg' } `
			| ForEach-Object {
				try {
					$threadSafeDictionary["numTotal"]++

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
						
						$threadSafeDictionary["numSkipped"]++
						return # continue behaves like break in ForEach-Object, use return intead
					}
				
					# sanitze string
					$DateTakenString = $DateTakenString -replace '[^0-9AaPpMm\.\:\ \/]', ''
					# parse to DateTime
					$DateTaken = Get-Date $DateTakenString
	
					$currentFileName = $_.Name
					$newFileName = $DateTaken.ToString($DateFormat) + "_" + $_.Name
				
					Rename-Item -Path $_.FullName -NewName $newFileName #-WhatIf -Confirm
					$threadSafeDictionary["numModified"]++
	
					Write-Verbose "Renamed file $currentFileName to $newFileName"
				}
				catch {
					$threadSafeDictionary["numErrored"]++
					Write-Error "an error occurred:"
					Write-Error "$_"
				}
			}
		} | Select-Object TotalMilliseconds -OutVariable runtimeMillis
	}


	# colored output
	Write-Host "`n`n	Script Finished Successfully`n" -ForegroundColor Green
	Write-Host "Modified " -NoNewline
	Write-Host $threadSafeDictionary["numModified"] -ForegroundColor Green -NoNewline
	Write-Host " files, skipped " -NoNewline
	Write-Host $threadSafeDictionary["numSkipped"] -ForegroundColor Yellow -NoNewline
	Write-Host " files missing the DateTaken property, and " -NoNewline
	Write-Host $threadSafeDictionary["numErrored"] -ForegroundColor Red -NoNewline
	Write-Host " files had errors. Total: " -NoNewline
	Write-Host $threadSafeDictionary["numTotal"] -ForegroundColor Blue
	Write-Host "$runtimeMillis"
}