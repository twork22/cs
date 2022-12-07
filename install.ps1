# . { iwr -useb https://raw.github.com/twork22/cs/main/install.ps1 } | iex
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        $CommandLine = "-ExecutionPolicy Bypass -File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
        Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
        Exit
    }
}

$onlinePath = "https://raw.github.com/twork22/cs/main/"

Function Get-Folder($where = "") {
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null;

    $foldername = New-Object System.Windows.Forms.FolderBrowserDialog;
    $foldername.Description = $where;
    $foldername.rootfolder = "MyComputer";
    $foldername.SelectedPath = "";
	$foldername.ShowNewFolderButton = $false;

    if ($foldername.ShowDialog() -eq "OK") {
        $folder += $foldername.SelectedPath;
		return $folder;
    }

	return $null;
}
Function Download($filename = "", $dest = "") {
	if (-Not($dest)) {
		Write-Host "Destination is not supplied.";
		return
	}
	if (-Not($filename)) {
		Write-Host "File name is not supplied.";
		return
	}

	$path = "$onlinePath"
	if ($userFolder) {
		$path += "/$userFolder/";
	}
	$path += $filename;
	Invoke-Webrequest -URI $path -UseBasicParsing -OutFile "$dest/$filename";
}

$userFolder = "";
$localAutoexec = "$PSScriptRoot/autoexec.cfg";
$localCfg = "$PSScriptRoot/config.cfg";
$localTestAutoexec = Test-Path $localAutoexec;
$localTestCfg = Test-Path $localCfg;
$loggedInUsr = Get-ItemPropertyValue -Path "HKCU:\Software\valve\Steam\ActiveProcess" -Name "ActiveUser";
$loggedInUsr = if ($loggedInUsr) { $loggedInUsr } else { $null };

Write-Host "$loggedInUsr"

if (-Not($localTestAutoexec) -Or -Not($localTestCfg)) {
	$userFolder = Read-Host -Prompt "User data folder? https://github.com/twork22/cs";
}

$autoexecDest = Get-Folder "Select 'autoexec.cfg' destination`n`n%steamapps%/common/Counter-Strike Global Offensive/csgo/cfg"
if ($autoexecDest -And -Not($localTestAutoexec)) {
	Download "autoexec.cfg" $autoexecDest;
}
if ($autoexecDest -And $localTestAutoexec) {
	Copy-Item $localAutoexec -Destination $autoexecDest;
}

$getUserConfigDestMsg = if ($loggedInUsr) { "Select 'config.cfg' destination (userdata)`n`n%Programfilesx86%/Steam/userdata" } else { "Select 'config.cfg' destination (userdata/*)`n`n%Programfilesx86%/Steam/userdata/*/730/local/cfg" };
$userConfigDest = if ($loggedInUsr) { "$(Get-Folder $getUserConfigDestMsg)/$loggedInusr/730/local/cfg" } else { "$(Get-Folder $getUserConfigDestMsg)/730/local/cfg" };
Write-Host "$userConfigDest";
if ($userConfigDest -And -Not(Test-Path $userConfigDest)) {
	New-Item $userConfigDest -ItemType Directory -Force;
}
if ($userConfigDest -And -Not($localTestCfg)) {
	Download "config.cfg" $userConfigDest;
}
if ($userConfigDest -And $localTestCfg) {
	Copy-Item $localCfg -Destination $userConfigDest;
}

$regFile = @"
Windows Registry Editor Version 5.00

; Mouse Tweaks
[HKEY_CURRENT_USER\Control Panel\Mouse]
"DoubleClickSpeed"="200"
"MouseSensitivity"="20"
"MouseSpeed"="0"

[HKEY_CURRENT_USER\Control Panel\Desktop]
"WheelScrollChars"="5"
"WheelScrollLines"="5"

"@;

$regFile | Out-File $env:temp/mod.reg;
taskkill /f /im explorer.exe;
regedit /s $env:temp/mod.reg;
Start-Sleep -s 3;
Remove-Item $env:temp/mod.reg;
explorer.exe;
