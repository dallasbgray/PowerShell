# menu to choose a repository you define in $repos, search for a filename, and then choose a file to open in Vim
# You should edit $repos & place your repository paths there
# Also edit the file types searched for in the Get-Childitem cmdlet
<#
    Todo: 
    1. pair each repository with specific file types to search to let this work with apps of different codebase types
    2. fix the menu system
        - validate user input, only allow valid options or commands
        - develop menu commands system? commands that work at anytime within any loop
#>

############ static variables ############
$menuCommands = @{
	x = 'e(x)it'
	y = '(y)es'
	c = '(c)ancel'
}


$repos = 'path_to_repo1', 'path_to_repo2'
$repoPrompt = 'Which repository would you like to open?'

############ functions ############
function Show-Menu
{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
		[object[]]$options,
	
		[ValidateNotNullOrEmpty()]
		[string]$prompt,
		
		[ValidateNotNullOrEmpty()]
		[string]$property
	)

	$menu = [ordered]@{}
	For ($i = 1; $i -le $options.Length; $i++) {
			$menu.Add("$i", ($options[$i-1]))
	}
	
    # add custom menu Commands
	$menu = $menu + $menuCommands
	
	# rewrite this to use format-table or format-wide, anything that makes it easier to see
	$menu.GetEnumerator() | ForEach-Object { 
		if ($menuCommands.ContainsKey($_.key))
		{ 
            # 'continue' looks like it should work but it only works with the foreach statement (which loads objects upfront) 
            #  & not foreach-object (which expects a piped datastream)
			return
		}
		
		if ($property) 
		{ Write-Host "$($_.key). $($_.value.$property)"}
		else 
		{ Write-Host "$($_.key). $($_.value)" }
	}

	if ($prompt -eq '') {
		$prompt = 'Select an option'
	}
	$choice = Read-Host "$prompt"
	
	$val = $menu.Item("$choice")
	$val
}


############ choose programming project ############
$path = Show-Menu -options $repos -prompt $repoPrompt
Write-Host "path $path"
Set-Location $path


############ search for files ############
Do {
    $searchVal = Read-Host 'Enter filename to search (searches *name* .ts, .html)'

    # get html or ts file names that include the input pattern, ignoring files that throw errors like temp or system files
    [object[]] $files = Get-Childitem -Recurse -Filter *$searchVal* -Include *.ts, *.html -ErrorAction SilentlyContinue 
    
    # prints file options
    if ($files.Length -eq 0) {
        Write-Host 'No Files Found'
	    continue
    }

    # requires some extra things to run Out-GridView, Windows has it built-in but this may not work in certain environments
	# $selection = $files | Out-GridView -OutputMode Single -Title 'Please select a file to open'

	# Get-Childitem returns an array of various types, but not specifying the property to access returns a string of the entire file path
	$selection = Show-Menu -options $files -prompt "Select a file or enter (y) to keep searching" -property 'Name'
	
	if (($selection) -and (!$menuCommands.ContainsValue($selection))) {
		Write-Host "file path: $selection"
		Start-Sleep -Seconds 1.5
		
		# open file in vim
		vim $selection
	}
} While ($menuCommands.ContainsValue($selection))


