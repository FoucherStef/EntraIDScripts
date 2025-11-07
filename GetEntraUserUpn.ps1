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