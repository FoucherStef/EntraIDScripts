# Script-scoped cache to avoid running dsregcmd multiple times
if (-not $script:__DsRegCache) { $script:__DsRegCache = $null }

function Get-DSRegOutput {
    if (-not $script:__DsRegCache) {
        $script:__DsRegCache = (& dsregcmd /status 2>$null) -join "`n"
    }
    return $script:__DsRegCache
}

function Get-EntraUserUpn {
    param()
    $dsreg = Get-DSRegOutput

    # 1) Try the specific "Executing Account Name" line (matches your screenshot)
    if ($dsreg -match '(?mi)^\s*Executing\s+Account\s+Name\s*:\s*(.+)$') {
        $acct = $matches[1].Trim()
        # If it's "DisplayName, upn@domain", take the UPN after the comma
        if ($acct -match ',\s*(.+)$') {
            $candidate = $matches[1].Trim()
            if ($candidate -match '(?i)[\w.+-]+@[\w.-]+\.\w{2,}') {
                return $candidate
            }
            return $candidate
        }
        # If it contains an @ anywhere, return that piece
        if ($acct -match '(?i)([\w.+-]+@[\w.-]+\.\w{2,})') {
            return $matches[1].Trim()
        }
        # No comma / no email — continue to broader searches below
    }

    # 2) Try "Primary User Name" line (alternate label)
    if ($dsreg -match '(?mi)^\s*Primary\s+User\s+Name\s*:\s*(.+)$') {
        $p = $matches[1].Trim()
        if ($p -match '(?i)([\w.+-]+@[\w.-]+\.\w{2,})') {
            return $matches[1].Trim()
        }
    }

    # 3) Fallback: search the whole dsreg output for the first email-like string
    if ($dsreg -match '(?i)([\w.+-]+@[\w.-]+\.\w{2,})') {
        return $matches[1].Trim()
    }

    # 4) Last resort: return current windows identity's name (DOMAIN\user)
    return [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
}

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
