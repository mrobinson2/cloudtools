Set-StrictMode -Version latest

<#
.SYNOPSIS
Returns all Azure Migrate projects within a specified Azure subscription.
.DESCRIPTION
The Get-AzMigrateProject cmdlet returns all Azure Migrate projects from a specified subscription.
.PARAMETER Token
Specifies an authentication token to use when retrieving information from Azure.
.PARAMETER SubscriptionID
Specifies the Azure subscription to query.
.EXAMPLE
Get all Azure Migrate projects within a specific Azure subscription.
PS C:\>Get-AzureMigrateProject -Token $token -SubscriptionID 45916f92-e9c3-4ed2-b8c2-d87aa129905f

.NOTES
TBD:
1. Consider returning 1 or multiple projects.
2. Return more meaningful object by extracting values from properties of a project.
3. Discern and return the display name or a project as well as the internal name/ID.
#>
function Get-AzureMigrateProject {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)][string]$Token,
        [Parameter(Mandatory = $true)][string]$SubscriptionID
    )

    $url = "https://management.azure.com/subscriptions/{0}/providers/Microsoft.Migrate/assessmentProjects?api-version=2019-10-01" -f $SubscriptionID

    $headers = @{
        "Authorization" = "Bearer $Token"
    }

    $response = Invoke-RestMethod -Uri $url -Headers $headers -ContentType "application/json" -Method "GET"
    return $response.value | ForEach-Object {
        [PSCustomObject]@{
            DisplayName = $_.properties.displayName
            ProjectID   = $_.id
        }
    }
}

<#
.SYNOPSIS
Returns all discovered machines within a specified Azure Migrate project.
.DESCRIPTION
The Get-AzureMigrateDiscoveredMachine cmdlet returns all machines discovered within a specified Azure Migrate project.
Adding the -GroupName parameter returns only machines associated with the specified Azure Migrate group.
.PARAMETER Token
Specifies an authentication token to use when retrieving information from Azure.
.PARAMETER SubscriptionID
Specifies the Azure subscription to query.
.PARAMETER ResourceGroup
Specifies the resource group containing the Azure Migrate project.
.PARAMETER Project
Specifies the Azure Migrate project to query.
.PARAMETER GroupName
Name of an Azure Migrate group from which to return a list of machines.
.EXAMPLE
Get all machines discovered within a specified Azure Migrate project.
PS C:\>Get-AzureMigrateDiscoveredMachine -Token $token -SubscriptionID SSID -ResourceGroup xx -Project xx
.EXAMPLE
Get machines discovered within a specified Azure Migrate project and associated with a specific group.
PS C:\>Get-AzureMigrateDiscoveredMachine -Token $token -SubscriptionID SSID -ResourceGroup xx -Project xx -GroupName MyGroup01

.NOTES
TBD:
1. Return object with more meaningful properties (i.e. extract info from .properties and populate top-level object as appropriate).
2. Handle case of empty project.
3. Handle cases of 1 discovered machine.
#>
function Get-AzureMigrateDiscoveredMachine {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)][string]$Token,
        [Parameter(Mandatory = $true)][string]$SubscriptionID,
        [Parameter(Mandatory = $true)][string]$ResourceGroup,
        [Parameter(Mandatory = $true)][string]$Project,
        [Parameter(Mandatory = $false)][string]$GroupName
    )

    $url = "https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Migrate/assessmentProjects/{2}/machines?api-version=2019-05-01&pageSize=2000" -f $SubscriptionID, $ResourceGroup, $Project
    if ($GroupName) {
        $url = "https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Migrate/assessmentprojects/{2}/machines?api-version=2019-05-01&pageSize=2000&%24filter=Properties/GroupName%20eq%20'{3}'" -f $SubscriptionID, $ResourceGroup, $Project, $GroupName
    }

    $headers = @{
        "Authorization" = "Bearer $Token"
    }

    $response = Invoke-RestMethod -Uri $url -Headers $headers -ContentType "application/json" -Method "GET"
    $machines = $response.value
    while ($response.nextLink) {
        $response = Invoke-RestMethod -Uri $response.nextLink -Headers $headers -ContentType "application/json" -Method "GET"
        $machines += $response.value
    }
    return $machines | ForEach-Object {
        [PSCustomObject]@{
            MachineName = $_.properties.machineName
            MachineID   = $_.id
        }
    }
}

<#
.SYNOPSIS
Returns details of machines assessed within a group by a specific assessment.
.DESCRIPTION
The Get-AzureMigrateAssessedMachine cmdlet returns details of machines assessed against a specific assessment within a specified Azure Migrate group.
.PARAMETER Token
Specifies an authentication token to use when retrieving information from Azure.
.PARAMETER SubscriptionID
Specifies the Azure subscription to query.
.PARAMETER ResourceGroup
Specifies the resource group containing the Azure Migrate project.
.PARAMETER Project
Specifies the Azure Migrate project to query.
.PARAMETER GroupName
Name of an Azure Migrate group from which to return a list of machines.
.PARAMETER AssessmentName
The name of the specific assessment for which to retrieve results from.
.EXAMPLE
Get all machines assessed against the assessment "assessment01" within the group "group01".
PS C:\>Get-AzureMigrateAssessedMachine -Token $token -SubscriptionID SSID -ResourceGroup xx -Project xx -GroupName group01 -AssessmentName assessment01

.NOTES
TBD:
1. Return object with more meaningful properties (i.e. extract info from .properties and populate top-level object as appropriate).
2. Handle case of empty project.
3. Handle cases of 1 discovered machine.
#>
function Get-AzureMigrateAssessedMachine {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)][string]$Token,
        [Parameter(Mandatory = $true)][string]$SubscriptionID,
        [Parameter(Mandatory = $true)][string]$ResourceGroup,
        [Parameter(Mandatory = $true)][string]$Project,
        [Parameter(Mandatory = $true)][string]$GroupName,
        [Parameter(Mandatory = $true)][string]$AssessmentName
    )

    $url = "https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Migrate/assessmentProjects/{2}/groups/{3}/assessments/{4}/assessedMachines/?api-version=2019-05-01&pageSize=2000" -f $SubscriptionID, $ResourceGroup, $Project, $GroupName, $AssessmentName

    $headers = @{
        "Authorization" = "Bearer $Token"
    }

    $response = Invoke-RestMethod -Uri $url -Headers $headers -ContentType "application/json" -Method "GET"
    return $response.value | ForEach-Object {
        [PSCustomObject]@{
            MachineName = $_.properties.machineName
            MachineID   = $_.id
        }
    }
}

<#
.SYNOPSIS
Returns all on-premises VMware sites associated with Azure Migrate.
.DESCRIPTION
The Get-AzureMigrateVMWareSite cmdlet returns all on-premises VMware sites associated with Azure Migrate.
.PARAMETER Token
Specifies an authentication token to use when retrieving information from Azure.
.PARAMETER SubscriptionID
Specifies the Azure subscription to query.
.PARAMETER ResourceGroup
Specifies the resource group containing the Azure Migrate project.
.EXAMPLE
Get all machines discovered within a specified Azure Migrate project.
PS C:\>Get-AzureMigrateVMWareSite -Token $token -SubscriptionID 45916f92-e9c3-4ed2-b8c2-d87aa129905f -ResourceGroup xx

.NOTES
TBD:
1. Return object with more meaningful properties (i.e. extract info from .properties and populate top-level object as appropriate).
2. Handle case of empty project.
3. Handle cases of 1 discovered machine.
#>
function Get-AzureMigrateVMWareSite {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)][string]$Token,
        [Parameter(Mandatory = $true)][string]$SubscriptionID,
        [Parameter(Mandatory = $true)][string]$ResourceGroup
    )

    $url = "https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.OffAzure/VMwareSites?api-version=2020-01-01-preview" -f $SubscriptionID, $ResourceGroup

    $headers = @{
        "Authorization" = "Bearer $Token"
    }

    $response = Invoke-RestMethod -Uri $url -Headers $headers -ContentType "application/json" -Method "GET"
    return $response.value | ForEach-Object {
        [PSCustomObject]@{
            SiteName = $_.properties.siteName
            SiteID   = $_.id
        }
    }
}