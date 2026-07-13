param(
    [string]$ProjectRoot = (Get-Location).Path,
    [string]$ReportFolder,
    [string]$OutFile,
    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-ReportFolder {
    param(
        [string]$Root,
        [string]$ExplicitReportFolder
    )

    if (-not [string]::IsNullOrWhiteSpace($ExplicitReportFolder)) {
        $resolved = Resolve-Path -Path $ExplicitReportFolder -ErrorAction Stop
        return $resolved.Path
    }

    $resolvedRoot = (Resolve-Path -Path $Root -ErrorAction Stop).Path
    $reportFolders = @(Get-ChildItem -Path $resolvedRoot -Directory -Filter "*.Report")

    if ($reportFolders.Count -eq 0) {
        throw "No '*.Report' folder found under '$resolvedRoot'."
    }

    if ($reportFolders.Count -gt 1) {
        $names = $reportFolders.Name -join ", "
        throw "Multiple '*.Report' folders found under '$resolvedRoot': $names. Pass -ReportFolder explicitly."
    }

    return $reportFolders[0].FullName
}

function Read-JsonFile {
    param([string]$Path)
    Get-Content -Path $Path -Raw | ConvertFrom-Json -Depth 100
}

function Get-NormalizedText {
    param([string[]]$Values)

    $joined = ($Values | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join " "
    $joined = [regex]::Replace($joined, "\s+", " ").Trim()
    if ([string]::IsNullOrWhiteSpace($joined)) {
        return $null
    }

    return $joined
}

function Get-TextboxLabel {
    param($VisualConfig)

    $paragraphs = $VisualConfig.visual.objects.general[0].properties.paragraphs
    if ($null -eq $paragraphs) {
        return $null
    }

    $values = New-Object System.Collections.Generic.List[string]
    foreach ($paragraph in $paragraphs) {
        if ($null -eq $paragraph.textRuns) {
            continue
        }

        foreach ($textRun in $paragraph.textRuns) {
            if ($textRun.PSObject.Properties.Name -contains "value") {
                $values.Add([string]$textRun.value)
            }
        }
    }

    return Get-NormalizedText -Values $values
}

function Get-FirstPropertyValue {
    param($Node)

    if ($null -eq $Node) {
        return $null
    }

    if ($Node -is [string]) {
        if ([string]::IsNullOrWhiteSpace($Node)) {
            return $null
        }

        return $Node.Trim()
    }

    if ($Node -is [System.Collections.IEnumerable] -and $Node -isnot [string]) {
        foreach ($item in $Node) {
            $value = Get-FirstPropertyValue -Node $item
            if ($null -ne $value) {
                return $value
            }
        }

        return $null
    }

    if ($Node.PSObject.Properties.Name -contains "value") {
        $value = Get-FirstPropertyValue -Node $Node.value
        if ($null -ne $value) {
            return $value
        }
    }

    foreach ($property in $Node.PSObject.Properties) {
        $value = Get-FirstPropertyValue -Node $property.Value
        if ($null -ne $value) {
            return $value
        }
    }

    return $null
}

function Get-VisualLabel {
    param($VisualConfig)

    if ($VisualConfig.PSObject.Properties.Name -notcontains "visual") {
        return $null
    }

    if ($null -eq $VisualConfig.visual) {
        return $null
    }

    if ($VisualConfig.visual.visualType -eq "textbox") {
        return Get-TextboxLabel -VisualConfig $VisualConfig
    }

    return Get-FirstPropertyValue -Node $VisualConfig.visual.objects
}

function Convert-ToNestedObjects {
    param(
        [System.Collections.IEnumerable]$Records,
        [string]$ParentGroupId
    )

    $items = New-Object System.Collections.Generic.List[object]
    foreach ($record in $Records) {
        $matchesParent = if ([string]::IsNullOrWhiteSpace($ParentGroupId)) {
            [string]::IsNullOrWhiteSpace([string]$record.parentGroupId)
        }
        else {
            [string]$record.parentGroupId -eq $ParentGroupId
        }

        if (-not $matchesParent) {
            continue
        }

        $item = [ordered]@{
            objectId = [string]$record.objectId
            objectName = [string]$record.objectName
            objectType = [string]$record.objectType
        }

        $children = @(Convert-ToNestedObjects -Records $Records -ParentGroupId ([string]$record.objectId))
        if ($children.Count -gt 0) {
            $item.children = $children
        }

        $items.Add($item)
    }

    return $items
}

$resolvedProjectRoot = (Resolve-Path -Path $ProjectRoot -ErrorAction Stop).Path
$resolvedReportFolder = Resolve-ReportFolder -Root $resolvedProjectRoot -ExplicitReportFolder $ReportFolder
$definitionRoot = Join-Path $resolvedReportFolder "definition"
$pagesRoot = Join-Path $definitionRoot "pages"
$pagesMetadataPath = Join-Path $pagesRoot "pages.json"

if (-not (Test-Path $pagesMetadataPath)) {
    throw "Could not find pages metadata file at '$pagesMetadataPath'."
}

$pagesMetadata = Read-JsonFile -Path $pagesMetadataPath
$pageOrder = @($pagesMetadata.pageOrder)
$activePageId = [string]$pagesMetadata.activePageName

$manifest = New-Object System.Collections.Generic.List[object]

foreach ($pageId in $pageOrder) {
    $pageDir = Join-Path $pagesRoot $pageId
    $pagePath = Join-Path $pageDir "page.json"
    if (-not (Test-Path $pagePath)) {
        continue
    }

    $page = Read-JsonFile -Path $pagePath
    $visualsDir = Join-Path $pageDir "visuals"
    $pageObjectName = [string]$page.displayName
    if ([string]::IsNullOrWhiteSpace($pageObjectName)) {
        $pageObjectName = [string]$page.name
    }

    $pageChildren = New-Object System.Collections.Generic.List[object]

    if (Test-Path $visualsDir) {
        foreach ($visualDir in Get-ChildItem -Path $visualsDir -Directory | Sort-Object Name) {
            $visualPath = Join-Path $visualDir.FullName "visual.json"
            if (-not (Test-Path $visualPath)) {
                continue
            }

            $visual = Read-JsonFile -Path $visualPath
            $hasVisual = $visual.PSObject.Properties.Name -contains "visual"
            $visualType = if ($hasVisual -and $null -ne $visual.visual -and $visual.visual.PSObject.Properties.Name -contains "visualType") {
                [string]$visual.visual.visualType
            }
            elseif ($visual.PSObject.Properties.Name -contains "visualGroup") {
                "visualGroup"
            }
            else {
                "unknown"
            }

            $objectName = Get-VisualLabel -VisualConfig $visual
            if ([string]::IsNullOrWhiteSpace($objectName)) {
                $objectName = $visualType
            }

            $pageChildren.Add([ordered]@{
                objectId = [string]$visual.name
                objectName = $objectName
                objectType = $visualType
                parentGroupId = if ($visual.PSObject.Properties.Name -contains "parentGroupName") { [string]$visual.parentGroupName } else { $null }
            })
        }
    }

    $pageEntry = [ordered]@{
        objectId = [string]$page.name
        objectName = $pageObjectName
        objectType = "page"
    }

    $nestedChildren = @(Convert-ToNestedObjects -Records $pageChildren -ParentGroupId $null)
    if ($nestedChildren.Count -gt 0) {
        $pageEntry.children = $nestedChildren
    }

    $manifest.Add($pageEntry)
}

if ([string]::IsNullOrWhiteSpace($OutFile)) {
    $reportName = [System.IO.Path]::GetFileNameWithoutExtension($resolvedReportFolder)
    $OutFile = Join-Path $resolvedProjectRoot ($reportName + ".object-id-manifest.json")
}

$outDir = Split-Path -Path $OutFile -Parent
if (-not [string]::IsNullOrWhiteSpace($outDir) -and -not (Test-Path $outDir)) {
    New-Item -Path $outDir -ItemType Directory -Force | Out-Null
}

$manifest | ConvertTo-Json -Depth 100 | Set-Content -Path $OutFile -Encoding UTF8
Write-Host "Wrote manifest: $OutFile"

if ($PassThru.IsPresent) {
    $manifest
}