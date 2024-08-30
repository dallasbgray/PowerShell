# scripts

scripts I think are useful and assist in everyday tasks

## Powershell

`FileUtilities.psm1` (module)
- `Rename-DatedImages` (functions in the module)

## Bash


## Running PowerShell Scripts

These are organized in modules and compatible with Powershell versions `>= 6.2.0`
How to import a module `PS C:\> Import-Module C:\_Scripts\FileUtilities`
- where `\FileUtilities` is a folder containing a .psm1 file, and probably a .psd1 file
- reimport the module after updating the code. To remove the module run `Remove-Module FileUtilities`
Find commands in a module `PS C:\> Get-Command -Module FileUtilities`
can run just by calling the function name
- `PS C:\> Verb-NounScriptName -Param1 Value1`

## Running Bash Scripts

on the first line of the script begin with `!#` + the result of running `which bash`, usually ends up looking like `#!/bin/bash`

add executable permissions
`$ chmod +x script-name-here`

run script
`$ ./script-name-here`
