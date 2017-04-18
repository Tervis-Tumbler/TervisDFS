function Copy-DirectoryWithAllAttributes{
    [CmdletBinding()]
    Param
        (
        [Parameter(Mandatory, ParameterSetName = "FixPermissions")]
        [Parameter(Mandatory, ParameterSetName = "MonitorforChanges")]
        [Parameter(Mandatory, ParameterSetName = "Default")]
        [string]$SourceDirectory,

        [Parameter(Mandatory, ParameterSetName = "FixPermissions")]
        [Parameter(Mandatory, ParameterSetName = "MonitorforChanges")]
        [Parameter(Mandatory, ParameterSetName = "Default")]
        $DestinationDirectory,

        [Parameter(Mandatory, ParameterSetName = "FixPermissions")]
        [switch]$FixPermissions,

        [Parameter(Mandatory, ParameterSetName = "MonitorforChanges")]
        [switch]$MonitorforChanges,

        [Parameter(ParameterSetName = "FixPermissions")]
        [Parameter(ParameterSetName = "MonitorforChanges")]
        [Parameter(ParameterSetName = "Default")]
        $Threads = "6"

        )
    if($FixPermissions -eq $true){
        robocopy $SourceDirectory $DestinationDirectory /MIR /SECFIX /TIMFIX /COPYALL /MT:$Threads /B /r:1 /w:1 /XD 'dfs' 'system volume information' 'DPMBackup' 'recycle' 'dfsrprivate' '.Trashes'  
    }
    if($MonitorforChanges -eq $true) {
        robocopy $SourceDirectory $DestinationDirectory /MIR /MON:5 /COPYALL /MT:$Threads /B /r:1 /w:1 /XD 'dfs' 'system volume information' 'DPMBackup' 'recycle' 'dfsrprivate' '.Trashes'
    }
    else{
        robocopy $SourceDirectory $DestinationDirectory /MIR /COPYALL /MT:$Threads /B /r:1 /w:1 /XD 'dfs' 'system volume information' 'DPMBackup' 'recycle' 'dfsrprivate' '.Trashes'
    }
}

function Set-FileServerConfiguration {
    param (
        [parameter(Mandatory)] [string] $Computername,
        [switch] $Restart
    )
        
    invoke-command -ComputerName $ComputerName -ScriptBlock {Set-NetFirewallProfile -Name domain -Enabled False}
    $ConfigPath = "\\fs1\disasterrecovery\Source Controlled Items\WindowsPowerShell\Desired State Configurations\Configuration Files\Base Configurations"
    $DFSServerDSCConfigurationFile = "$ConfigPath\FileServerBase.ps1"
    New-Item -Path $ConfigPath\FileServerBase -ItemType Directory
    . $DFSServerDSCConfigurationFile
    FileServerBase -Computername $ComputerName -OutputPath $ConfigPath\FileServerBase
    Start-DscConfiguration -path $ConfigPath\FileServerBase -Wait -Verbose -Force
    remove-item -path $configpath\FileServerBase -recurse -force
    if($Restart) {
        Restart-Computer -ComputerName $Computername -Force
    }
}


