function Get-EntraJoinInfo {
    $out = [ordered]@{
        ComputerName   = $env:COMPUTERNAME
        PartOfDomain   = $false
        Domain         = $null
        AzureAdJoined  = $null
        TenantId       = $null
        TenantName     = $null
        TenantDomain   = $null
        RegistryInfo   = $null
        DsregRaw       = $null
    }

    # 1) on-prem domain info
    try {
        $cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
        $out.PartOfDomain = $cs.PartOfDomain
        $out.Domain = $cs.Domain
    } catch {}

    # 2) dsregcmd
    try {
        $ds = (& dsregcmd.exe /status 2>$null) -join "`n"
        $out.DsregRaw = $ds
        if ($ds -match 'AzureAdJoined\s*:\s*(Yes|No)') { $out.AzureAdJoined = $matches[1] }
        if ($ds -match 'TenantId\s*:\s*([0-9a-fA-F-]{36})') { $out.TenantId = $matches[1] }
        if ($ds -match 'TenantName\s*:\s*(.+)$') { $out.TenantName = $matches[1].Trim() }
        if ($ds -match 'TenantDomain\s*:\s*(.+)$') { $out.TenantDomain = $matches[1].Trim() }
    } catch {}

    # 3) registry (selected keys)
    $reg = @{}
    foreach ($p in @('HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo','HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CDJ\AAD')) {
        if (Test-Path $p) {
            $reg[$p] = (Get-ItemProperty -Path $p | Select-Object * -ExcludeProperty PS* )
        } else { $reg[$p] = $null }
    }
    $out.RegistryInfo = $reg
    [pscustomobject]$out
}

# Run it
Get-EntraJoinInfo | Format-List
