function Save-PSBiteFile {
    <#
    .SYNOPSIS
        Saves an array of text lines to a file with UTF-8 encoding for the PSBite editor.

    .DESCRIPTION
        Writes the provided array of strings to the specified file path using UTF-8 encoding.
        Provides user feedback through PSBite messaging system with success or error notifications.
        This function is the core file saving mechanism for both local and remote PSBite operations.

    .PARAMETER Lines
        Array of strings representing the lines of text to be saved to the file.
        Each element in the array represents one line in the output file.

    .PARAMETER FilePath
        The full path where the file should be saved. If the file exists, it will be overwritten.
        If the directory doesn't exist, the operation will fail with an error message.

    .EXAMPLE
        $fileContent = @("function Test {", "    Write-Host 'Hello'", "}")
        Save-PSBiteFile -Lines $fileContent -FilePath "C:\Scripts\test.ps1"

        Saves a simple PowerShell function to a file.

    .EXAMPLE
        Save-PSBiteFile -Lines $editorLines -FilePath "C:\temp\document.txt"

        Saves the current editor content to a text file.

    .EXAMPLE
        # Empty file creation
        Save-PSBiteFile -Lines @("") -FilePath "C:\new\empty.txt"

        Creates an empty file with a single blank line.

    .FUNCTIONALITY
        File operations for PSBite text editor

    .NOTES
        Author: Arnaud Charles
        GitHub: https://github.com/arnaudcharles
        LinkedIn: https://www.linkedin.com/in/arnaudcharles
    #>
    [OutputType()]
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowEmptyCollection()]
        [string[]]$Lines = @(""),

        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    # If content is removed or empty, ensure at least one blank line is written to avoid errors.
    if (-not $Lines -or $Lines.Count -eq 0) {
        $Lines = @("")
    }
    try {
        $Lines | Set-Content -Path $FilePath -Encoding UTF8 -Force
        Write-PSBiteMessage "💾 File saved: $FilePath" "Green"
    } catch {
        Write-PSBiteMessage "❌ Error saving file: $_" "Red"
    }
}
