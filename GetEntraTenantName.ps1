function Get-EntraTenantName {
    param()
    $dsreg = Get-DSRegOutput

    # Robust TenantName match (case-insensitive, line-based)
    if ($dsreg -match '(?mi)^\s*TenantName\s*:\s*(.+)$') {
        return $matches[1].Trim()
    }

    # Fallback: TenantDomain sometimes present and is useful
    if ($dsreg -match '(?mi)^\s*TenantDomain\s*:\s*(.+)$') {
        return $matches[1].Trim()
    }

    # Last resort: TenantId (GUID) if no friendly name available
    if ($dsreg -match '(?mi)^\s*TenantId\s*:\s*([0-9a-fA-F-]{36})') {
        return $matches[1].Trim()
    }

    return $null
}