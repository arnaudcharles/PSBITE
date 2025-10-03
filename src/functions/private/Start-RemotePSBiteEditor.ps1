<#
.SYNOPSIS
Briefly describes the main functionality of the script or function.

.DESCRIPTION
Provides a detailed explanation of the purpose, operation, and usage context of the script or function.

.PARAMETER <ParameterName>
Describes the role and usage of each parameter.

.EXAMPLE
Shows an example of how to use the script or function.

.NOTES
Adds additional information, such as the author, creation date, or important remarks.
#>
function Start-RemotePSBiteEditor {
    [OutputType()]
    [CmdletBinding()]
    param(
        [string]$LocalPath,
        [string]$RemotePath,
        [System.Management.Automation.Runspaces.PSSession]$Session,
        [string]$ComputerName,

        [Parameter()]
        [switch]$AutoSave
    )

    # Load file
    [string[]]$lines = @()
    $content = Get-Content $LocalPath
    if ($null -eq $content) {
        $lines = [string[]]@(" ")
    } elseif ($content -is [string]) {
        $lines = [string[]]@($content)
    } else {
        $lines = [string[]]$content
    }

    $cursorRow = 0
    $cursorCol = 0
    $mode = "NORMAL"
    $saved = $true
    $scrollOffset = 0
    $lastSaveTime = Get-Date
    $autoSaveInterval = [TimeSpan]::FromMinutes(5)

    try {
        while ($true) {
            Write-PSBiteEditor -Lines $lines -CursorRow $cursorRow -CursorCol $cursorCol -Mode $mode -FilePath "$ComputerName`:$RemotePath" -Saved $saved -IsRemote $true -ScrollOffset ([ref]$scrollOffset)

            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

            if ($AutoSave -and ((Get-Date) - $lastSaveTime) -ge $autoSaveInterval) {
                if (-not $saved) {
                    Save-PSBiteFile -Lines $lines -FilePath $LocalPath
                    try {
                        Copy-Item -Path $LocalPath -Destination $RemotePath -ToSession $Session -Force
                        $saved = $true
                        $lastSaveTime = Get-Date
                        Write-PSBiteMessage "💾 AutoSave: File saved and synced (5 min elapsed)" "Green"
                        Start-Sleep -Milliseconds 1000
                    } catch {
                        Write-PSBiteMessage "❌ AutoSave failed: $_" "Red"
                        Start-Sleep -Milliseconds 1000
                    }
                } else {
                    $lastSaveTime = Get-Date
                }
            }

            $result = Invoke-RemotePSBiteKeyPress -Key $key -Lines ([ref]$lines) -CursorRow ([ref]$cursorRow) -CursorCol ([ref]$cursorCol) -Mode ([ref]$mode) -LocalPath $LocalPath -RemotePath $RemotePath -Session $Session -ComputerName $ComputerName -Saved ([ref]$saved) -ScrollOffset ([ref]$scrollOffset)

            if ($result -eq "EXIT") {
                break
            }
        }
    } finally {
        [Console]::Clear()
    }
}
