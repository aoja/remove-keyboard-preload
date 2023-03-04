# Remove Extra Keyboard Preloads
I use Windows Remote Desktop and alternate keyboard layouts a lot. Sometimes this results in artefacts where you get seemingly extra layouts to the flyout menu. This script is for removing those easily. The script requires you to reboot once the changes are done and will help with a system restore point before doing anything, just in case.

## Usage

First you need to allow PowerShell to execute scripts on your system if you haven't done so. Configure your PowerShell into `Bypass` policy for the *current user* by typing in the following command:

```
Set-ExecutionPolicy -Scope CurrentUser Bypass
```

Now simply run the script with PowerShell and follow the prompts.

When the changes are done and you don't wish to run further PowerShell scripts, you can set the execution level back to what it should be with:

```
Set-ExecutionPolicy -Scope CurrentUser Default
```

Note: For now there is no way to revert the changes. However, the script prompts you for a generation of a new Windows System Restore Point before doing anything.