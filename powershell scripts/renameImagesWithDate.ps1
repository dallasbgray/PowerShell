
Get-ChildItem C:\Path-To-Photos-Here\photos `
| Where-Object { $_.extension -in '.jpg','.jpeg' } `
| ForEach-Object {
    try {
		$DateFormat = 'yyyy-MM-dd'
		$DateTakenWinApi = 12
		$DateCreatedWinApi = 4

		if ($null -eq $Shell) {
			$Shell = New-Object -ComObject shell.application
		}
	 
		$dir = $Shell.Namespace($_.DirectoryName)

		$DateTakenString = $dir.GetDetailsOf($dir.ParseName($_.Name), $DateTakenWinApi)
		if ($DateTakenString -eq '') {
			# can also use DateCreated as a substitute for DateTaken
			# $DateTakenString = $dir.GetDetailsOf($dir.ParseName($_.Name), $DateCreatedWinApi)
			continue
		}
		
		# sanitze string
		$DateTakenString = $DateTakenString -replace '[^0-9AaPpMm\.\:\ \/]', ''
		# parse to DateTime
		$DateTaken = Get-Date $DateTakenString

		$currentFileName = $_.Name
		$newFileName = $DateTaken.ToString($DateFormat) + "_" + $_.Name
		
		Rename-Item -Path $_.FullName -NewName $newFileName #-WhatIf -Confirm
		
		Write-Host "Renamed file $currentFileName to $newFileName"
    }
	catch {
		Write-Error "_an error occurred:"
		Write-Error "_ $_"
	}
}
