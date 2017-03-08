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
        robocopy $SourceDirectory $DestinationDirectory /MIR /MON:5 /COPYALL /MT:$Threads /B /r:1 /w:1 /XD 'dfs' 'system volume information' 'DPMBackup' 'recycle' 'dfsrprivate' '.Trashes'
    }
}

function Invoke-ProvisionDFSServer {
    param (
        [parameter(Mandatory)] [string] $Computername
    )
        
    invoke-command -ComputerName $ComputerName -ScriptBlock {Set-NetFirewallProfile -Name domain -Enabled False}
    $ConfigPath = "\\fs1\disasterrecovery\Source Controlled Items\WindowsPowerShell\Desired State Configurations\Configuration Files\Base Configurations"
    New-Item -Path $ConfigPath\DFSServerBase -ItemType Directory
    DFSServerBase -Computername $ComputerName -OutputPath $ConfigPath
    Start-DscConfiguration -path $ConfigPath -Wait -Verbose -Force
    remove-item -path $configpath\DFSServerBase -recurse -force

}

Configuration DFSServerBase
{
param (
    [Parameter(Mandatory=$true)] $Computername
)
    Node $Computername
    {
        Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
        WindowsFeature Deduplication
        {
            Ensure = “Present”
            Name = “FS-Data-Deduplication”
            IncludeAllSubFeature = $true
        }
        WindowsFeature DSFR
        {
            Ensure = “Present”
            Name = “FS-DFS-Replication”
            IncludeAllSubFeature = $true
        }
        WindowsFeature DSFN
        {
            Ensure = “Present”
            Name = “FS-DFS-Namespace”
            IncludeAllSubFeature = $true
        }
        WindowsFeature MPIO
        {
            Ensure = “Present”
            Name = “Multipath-IO”
        }
        WindowsFeature SNMP
        {
            Ensure = “Present”
            Name = “SNMP-Service”
            IncludeAllSubFeature = $true
        }
        Registry MPIO1
        {
            Ensure = "Present"  # You can also set Ensure to "Absent"
            Key = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\MPDEV"
            ValueType = "Multistring"
            ValueName = "MPIOSupportedDeviceList"
            ValueData = "DGC     RAID 3","DGC     RAID 5","DGC     RAID 1","DGC     RAID 0","DGC     RAID 10","DGC     VRAID","DGC     DISK","DGC     LUNZ","DELL    Universal Xport","DELL    MD38xx"
        }
        Registry MPIO2
        {
            Ensure = "Present"  # You can also set Ensure to "Absent"
            Key = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\msdsm\Parameters"
            ValueType = "Multistring"
            ValueName = "DsmSupportedDeviceList"
            ValueData = "DGC     RAID 3","DGC     RAID 5","DGC     RAID 1","DGC     RAID 0","DGC     RAID 10","DGC     VRAID","DGC     DISK","DGC     LUNZ","DELL    Universal Xport","DELL    MD38xx"
        }
        Registry SNMP-PermittedManagers
        {
            Ensure = "Present"  # You can also set Ensure to "Absent"
            Key = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SNMP\Parameters\PermittedManagers"
            ValueType = "String"
            ValueName = "2"
            ValueData = "orion.tervis.prv"
        }
        Registry SNMP-ValidCommunities
        {
            Ensure = "Present"  # You can also set Ensure to "Absent"
            Key = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SNMP\Parameters\Validcommunities"
            ValueType = "DWORD"
            ValueName = "ttComStr201"
            ValueData = "4"
        }

    }
}


