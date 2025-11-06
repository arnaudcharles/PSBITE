<#
.SYNOPSIS
Describes the purpose and functionality of the selected code.

.DESCRIPTION
Provides a detailed explanation of what the code does, its workflow, and any important implementation details.

.PARAMETER <ParameterName>
Describes each parameter used in the code, including its type and expected values.

.EXAMPLE
Shows an example of how to use the code or function.

.NOTES
Additional information, such as author, date, or references.

#>
function Write-PSBiteMessage {
    [OutputType()]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $true)]
        [string]$Color
    )

    $consoleHeight = $Host.UI.RawUI.WindowSize.Height
    [Console]::SetCursorPosition(0, $consoleHeight - 1)
    Write-Host $Message -ForegroundColor $Color
    Start-Sleep -Seconds 1
}