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
        robocopy $SourceDirectory $DestinationDirectory /MIR /SECFIX /TIMFIX /COPYALL /MT:$Threads /B /r:1 /w:1 /XD 'dfs' 'system volume information' 'DPMBackup' 'recycle' 'dfsrprivate'    
    }
    if($MonitorforChanges -eq $true) {
        robocopy $SourceDirectory $DestinationDirectory /MIR /MON:5 /COPYALL /MT:$Threads /B /r:1 /w:1 /XD 'dfs' 'system volume information' 'DPMBackup' 'recycle' 'dfsrprivate'    
    }
    else{
        robocopy $SourceDirectory $DestinationDirectory /MIR /MON:5 /COPYALL /MT:$Threads /B /r:1 /w:1 /XD 'dfs' 'system volume information' 'DPMBackup' 'recycle' 'dfsrprivate'
    }
}


