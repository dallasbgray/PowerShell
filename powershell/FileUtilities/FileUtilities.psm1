<#
.SYNOPSIS
    Prepends a formatted date to the beginning of image file names
.DESCRIPTION
    Runs Get-ChildItem on the provided path and filters Where-Object file extensions are certain image types. Then attempts to use the Windows Shell COM object to access the Date Taken property that isn't directly accessible through .NET's System.IO classes. If this date is found, it then formats & prepends that to the beginning of the image filename
.PARAMETER FolderPath
    Specifies a path to the folder of images to rename
.PARAMETER Extension
	singular file extension to filter by, e.g. '.jpg', '.jpeg', or '.cr2'
.PARAMETER Revert
	attempts to revert the changes made previously by the command by matching the beginning of the filename with the formatted prefix & removing it
.EXAMPLE
    PS C:\> Rename-DatedImages -Verbose -FolderPath C:\Path-To-Photos-Here\photos
.NOTES
    Author: Dallas Gray
    Date:   August 8th, 2024
#>
Function Rename-DatedImages {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateScript(
			{ Test-Path -Path $_ },
			ErrorMessage = "'{0}' is not a valid directory according to '{1}'")
		]
		[string]$FolderPath,

		[string]$Extension,
		
		[switch]$Revert
	)

	# thread-safe in order to allow the -Parallel option in ForEach-Object in a future implementation
	$threadSafeDictionary = [System.Collections.Concurrent.ConcurrentDictionary[string, int]]::new()
	$threadSafeDictionary.TryAdd("numTotal", 0) > $null # redirect to $null to ignore the return value
	$threadSafeDictionary.TryAdd("numModified", 0) > $null
	$threadSafeDictionary.TryAdd("numSkipped", 0) > $null
	$threadSafeDictionary.TryAdd("numErrored", 0) > $null

	$Extensions = if ($Extension) { $Extension } else { '.jpg', '.jpeg', '.cr2' }
	Write-Host "`n`n	Renaming Images with file extensions $Extensions...`n" -ForegroundColor DarkBlue
 
	Measure-Command {
		Get-ChildItem -Recurse -Depth 3 -Path $FolderPath `
		| Where-Object { $_.extension -in $Extensions } `
		| ForEach-Object {
			try {
				$threadSafeDictionary["numTotal"]++

				$DateFormat = 'yyyy-MM-dd'
				$DateFormatRegex = '^\d{4}-?\d{2}-?\d{0,2}[-_]?'
				$DateTakenWinApi = 12
				# $DateCreatedWinApi = 4
				$currentFileName = $_.Name
				$newFileName = ""
					
				if ($Revert) {
					if ($currentFileName -match $DateFormatRegex) {
						# remove prefix if matched
						$newFileName = $currentFileName -replace $DateFormatRegex, ""
					}
				}
				else {
					# attempt to retrieve the Date Taken property
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

					$newFileName = $DateTaken.ToString($DateFormat) + "-" + $_.Name
				}
	
				if (![string]::IsNullOrWhiteSpace($newFileName)) {
					Rename-Item -Path $_.FullName -NewName $newFileName #-WhatIf -Confirm
					$threadSafeDictionary["numModified"]++
	
					Write-Verbose "Renamed file $currentFileName to $newFileName"
				}
			}
			catch {
				$threadSafeDictionary["numErrored"]++
				Write-Error "an error occurred:"
				Write-Error "$_"
			}
		}
	} | Select-Object TotalMilliseconds -OutVariable runtimeMillis


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


<#
.SYNOPSIS
    Warning: Parallel implementation is very slow, recommended to not use this function! Prepends a formatted date to the beginning of image file names
.DESCRIPTION
    Runs Get-ChildItem on the provided path and filters Where-Object file extensions are certain image types. Then attempts to use the Windows Shell COM object to access the Date Taken property that isn't directly accessible through .NET's System.IO classes. If this date is found, it then formats & prepends that to the beginning of the image filename
.PARAMETER FolderPath
    Specifies a path to the folder of images to rename
.PARAMETER Extension
	singular file extension to filter by, e.g. '.jpg', '.jpeg', or '.cr2'
.EXAMPLE
    PS C:\> Rename-DatedImages -Verbose -FolderPath C:\Path-To-Photos-Here\photos
.NOTES
    Author: Dallas Gray
    Date:   August 29th, 2024
#>
Function Rename-DatedImagesParallel {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateScript(
			{ Test-Path -Path $_ },
			ErrorMessage = "'{0}' is not a valid directory according to '{1}'")
		]
		[string]$FolderPath,

		[string]$Extension
	)

	# thread-safe in order to allow the -Parallel option in ForEach-Object
	$threadSafeDictionary = [System.Collections.Concurrent.ConcurrentDictionary[string, int]]::new()
	$threadSafeDictionary.TryAdd("numTotal", 0) > $null # redirect to $null to ignore the return value
	$threadSafeDictionary.TryAdd("numModified", 0) > $null
	$threadSafeDictionary.TryAdd("numSkipped", 0) > $null
	$threadSafeDictionary.TryAdd("numErrored", 0) > $null

	$Extensions = if ($Extension) { $Extension } else { '.jpg', '.jpeg', '.cr2' }
	Write-Host "`n`n	Renaming Images with file extensions $Extensions...`n" -ForegroundColor DarkBlue
	Write-Host "Warning: Parallel implementation is very slow, recommended to not use this function" -BackgroundColor Red

	Measure-Command {
		Get-ChildItem -Recurse -Depth 5 -Path $FolderPath `
		| Where-Object { $_.extension -in $Extensions } `
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
				$newFileName = $DateTaken.ToString($DateFormat) + "-" + $_.Name
				
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