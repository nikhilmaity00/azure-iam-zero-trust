Connect-MgGraph -Scopes "RoleManagement.Read.Directory", "Directory.Read.All"

# 1. Build lookup table of RoleDefinitionId -> Role DisplayName
$roleDefs = @{}
Get-MgRoleManagementDirectoryRoleDefinition | ForEach-Object {
    $roleDefs[$_.Id] = $_.DisplayName
}

# Helper to resolve PrincipalId -> Name, Type, and UPN
function Resolve-PrincipalDetails {
    param([string]$PrincipalId)

    $obj = Get-MgDirectoryObject -DirectoryObjectId $PrincipalId -ErrorAction SilentlyContinue
    if (-not $obj) {
        return [PSCustomObject]@{
            PrincipalName = "Unresolved ($PrincipalId)"
            PrincipalType = "Unknown"
            UPN           = ""
        }
    }

    $odataType = $obj.AdditionalProperties['@odata.type']
    $upn       = $obj.AdditionalProperties['userPrincipalName']
    $dispName  = $obj.AdditionalProperties['displayName']

    if (-not $dispName) {
        $dispName = $PrincipalId
    }

    $typeLabel = switch -Wildcard ($odataType) {
        "*user"             { "User" }
        "*group"            { "Group" }
        "*servicePrincipal" { "ServicePrincipal" }
        default             { if ($odataType) { $odataType } else { "DirectoryObject" } }
    }

    [PSCustomObject]@{
        PrincipalName = $dispName
        PrincipalType = $typeLabel
        UPN           = if ($upn) { $upn } else { "" }
    }
}

# 2. Export Active Directory Role Assignments
$activeRows = Get-MgRoleManagementDirectoryRoleAssignment -All | ForEach-Object {
    $p = Resolve-PrincipalDetails -PrincipalId $_.PrincipalId
    [PSCustomObject]@{
        RoleName         = if ($roleDefs.ContainsKey($_.RoleDefinitionId)) { $roleDefs[$_.RoleDefinitionId] } else { $_.RoleDefinitionId }
        PrincipalName    = $p.PrincipalName
        PrincipalType    = $p.PrincipalType
        UPN              = $p.UPN
        PrincipalId      = $_.PrincipalId
        ScopeType        = if ($_.DirectoryScopeId -eq "/") { "TenantWide" } else { "Scoped" }
        DirectoryScopeId = $_.DirectoryScopeId
        AssignmentId     = $_.Id
    }
}

$activeCsvPath = "./entra-active-role-assignments.csv"
$activeRows | Export-Csv -Path $activeCsvPath -NoTypeInformation

# 3. Export PIM Eligible Role Schedules (when available / licensed)
try {
    $eligibleRows = Get-MgRoleManagementDirectoryRoleEligibilitySchedule -All -ErrorAction Stop | ForEach-Object {
        $p = Resolve-PrincipalDetails -PrincipalId $_.PrincipalId
        $endDate = $_.ScheduleInfo.Expiration.EndDateTime
        [PSCustomObject]@{
            RoleName         = if ($roleDefs.ContainsKey($_.RoleDefinitionId)) { $roleDefs[$_.RoleDefinitionId] } else { $_.RoleDefinitionId }
            PrincipalName    = $p.PrincipalName
            PrincipalType    = $p.PrincipalType
            UPN              = $p.UPN
            PrincipalId      = $_.PrincipalId
            ScopeType        = if ($_.DirectoryScopeId -eq "/") { "TenantWide" } else { "Scoped" }
            DirectoryScopeId = $_.DirectoryScopeId
            StartDateTime    = $_.ScheduleInfo.StartDateTime
            ExpirationType   = $_.ScheduleInfo.Expiration.Type
            EndDateTime      = if ($endDate) { $endDate } else { "Permanent/NoExpiry" }
        }
    }

    $eligibleCsvPath = "./entra-pim-eligible-schedules.csv"
    $eligibleRows | Export-Csv -Path $eligibleCsvPath -NoTypeInformation
    Write-Host "Exported active roles to $activeCsvPath and PIM eligible schedules to $eligibleCsvPath"
}
catch {
    Write-Warning "Could not query PIM eligible schedules (check Entra ID P2 license or permissions): $($_.Exception.Message)"
    Write-Host "Exported active roles to $activeCsvPath"
}