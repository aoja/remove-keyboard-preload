# MIT License

# Copyright (c) 2023- Antti J. Oja <a.oja@outlook.com>

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


# Get the ID and security principal of the current user account
$myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($myWindowsID)

# Get the security principal for the administrator role
$adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator

# Check to see if we are currently running as an administrator
if ($myWindowsPrincipal.IsInRole($adminRole))
{
    # We are running as an administrator, so change the title and background colour to indicate this
    $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)"
    $Host.UI.RawUI.BackgroundColor = "DarkBlue"

    Clear-Host
}
else
{
    # We are not running as an administrator, so relaunch as administrator
    Start-Process pwsh.exe -Verb RunAs -ArgumentList $myInvocation.MyCommand.Definition

    # Exit from the current, unelevated, process
    Exit
}

# Set up the message labels
$message = "IMPORTANT"
$question = "Would you like a system restore point generated before proceeding?"

# Set up the choice for generating a System Restore point before continuing
$choices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]
$choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList "&Yes", "Generates a system restore point before proceeding."))
$choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList "&No", "Proceeds without generating a system restore point."))

# Present the choice
$decision = $Host.UI.PromptForChoice($message, $question, $choices, 0)

if ($decision -eq 0)
{
    # The user selected 'yes'

    # Generate the restore point with the selected tags
    Checkpoint-Computer -Description "Before adjusting keymap preload" -RestorePointType MODIFY_SETTINGS
}

# Get the current keyboard layout preload settings
$preload = Get-ItemProperty -Path 'HKCU:\Keyboard Layout\Preload'
$layouts = @{}

# Get the layout information for each layout ID in the preload key
foreach ($key in $preload.PSObject.Properties | Where-Object { $_.Name -match '^\d+$' }) {
    $layoutID = $key.Value
    $layoutInfo = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\$layoutID"
    $layouts[$layoutID] = $layoutInfo
}

Write-Host "Choose a layout to remove:"

$i = 1

foreach ($layoutID in $layouts.Keys) {
    $layoutText = $layouts[$layoutID].'Layout Text'
    Write-Host "$i. $layoutText"
    $i++
}

$choice = Read-Host "Enter the number of the layout you want to select"

if ($choice -ge 1 -and $choice -le $layouts.Count) {
    $selectedLayoutID = ($layouts.Keys | Select-Object -Index ($choice - 1))
    $selectedLayout = $layouts[$selectedLayoutID]
    
    # Do something with the $selectedLayout object here
    Write-Host "You selected the layout with ID $selectedLayoutID and layout text $($selectedLayout.'Layout Text')"
    
    # Removal happens here
    $preloadKey = Get-Item -Path 'HKCU:\Keyboard Layout\Preload'

    foreach ($valueName in $preloadKey.GetValueNames()) {
        # Check if the value data equals $selectedLayoutID
        if ($preloadKey.GetValue($valueName) -eq $selectedLayoutID) {
            # Confirm with the user before deleting the value
            $confirm = Read-Host "Are you sure you want to delete the '$valueName' value with data '$selectedLayoutID'? (Y/N)"
            if ($confirm -eq "Y") {
                # Delete the value from the preload key
                Remove-ItemProperty -Path 'HKCU:\Keyboard Layout\Preload' -Name $valueName
                Write-Host "Value '$valueName' with data '$selectedLayoutID' deleted from HKCU:\Keyboard Layout\Preload"
            } else {
                Write-Host "Value '$valueName' with data '$selectedLayoutID' not deleted from HKCU:\Keyboard Layout\Preload"
            }
        }
    }
} else {
    Write-Host "Invalid choice. Re-run the script to try again."
}

# Wait for any key to be pressed at the end so the shell won't just vanish
Pause
Exit