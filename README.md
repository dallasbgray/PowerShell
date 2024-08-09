# scripts
scripts I think are useful and assist in everyday tasks


### PowerShell Scripts
These are organized in modules
- Compatible with Powershell versions >= 6.2.0
How to import a module `PS C:\> Import-Module C:\Scripts\FileUtilities`
- where `\FileUtilities` is a folder containing a .psm1 file, and probably a .psd1 file
- reimport the module after updating the code. To remove the module run `Remove-Module FileUtilities`
Find commands in a module `PS C:\> Get-Command -Module FileUtilities`

Scripts
    `FileUtilities.psm1`
    Functions
        `Rename-DatedImages`
