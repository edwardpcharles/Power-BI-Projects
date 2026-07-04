param(
    [string]$PageId,

    [string]$GroupId,

    [double]$PaddingPx,

    [string]$ProjectRoot = (Get-Location).Path,

    [string]$ShapeId,

    [switch]$Reload
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($PageId)) {
    $PageId = Read-Host "Enter PageId"
}

if ([string]::IsNullOrWhiteSpace($GroupId)) {
    $GroupId = Read-Host "Enter GroupId"
}

if ($PSBoundParameters.ContainsKey("PaddingPx") -eq $false) {
    $paddingInput = Read-Host "Enter padding in px"
    if ([double]::TryParse($paddingInput, [ref]$PaddingPx) -eq $false) {
        throw "PaddingPx must be a valid number."
    }
}

function New-HexId {
    param([int]$Length = 20)
    $chars = "0123456789abcdef".ToCharArray()
    -join (1..$Length | ForEach-Object { $chars | Get-Random })
}

function Resolve-PagesRoot {
    param([string]$Root)

    $direct = Join-Path $Root "definition\pages"
    if (Test-Path $direct) {
        return $direct
    }

    $reportFolder = Get-ChildItem -Path $Root -Directory -Filter "*.Report" | Select-Object -First 1
    if ($null -eq $reportFolder) {
        throw "Could not find a '*.Report' folder under '$Root'."
    }

    $pages = Join-Path $reportFolder.FullName "definition\pages"
    if (-not (Test-Path $pages)) {
        throw "Could not find pages folder at '$pages'."
    }

    return $pages
}

$pagesRoot = Resolve-PagesRoot -Root (Resolve-Path $ProjectRoot).Path
$pageDir = Join-Path $pagesRoot $PageId
$visualsDir = Join-Path $pageDir "visuals"
$groupVisualPath = Join-Path $visualsDir "$GroupId\visual.json"

if (-not (Test-Path $groupVisualPath)) {
    throw "Group visual.json not found: $groupVisualPath"
}

$group = Get-Content -Path $groupVisualPath -Raw | ConvertFrom-Json -Depth 100
if ($null -eq $group.visualGroup) {
    throw "Visual '$GroupId' in page '$PageId' is not a visualGroup."
}

if ([string]::IsNullOrWhiteSpace($ShapeId)) {
    $ShapeId = New-HexId -Length 20
}

$childZValues = @()
Get-ChildItem -Path $visualsDir -Directory | ForEach-Object {
    $visualPath = Join-Path $_.FullName "visual.json"
    if (-not (Test-Path $visualPath)) {
        return
    }

    $v = Get-Content -Path $visualPath -Raw | ConvertFrom-Json -Depth 100
    $hasParentGroup = $v.PSObject.Properties.Name -contains "parentGroupName"
    if ($hasParentGroup -and $v.parentGroupName -eq $GroupId -and $null -ne $v.position -and $null -ne $v.position.z) {
        $childZValues += [double]$v.position.z
    }
}

$shapeZ = if ($childZValues.Count -gt 0) {
    ([double](($childZValues | Measure-Object -Minimum).Minimum)) - 1
}
else {
    -1
}

$shapePosition = [ordered]@{
    x = -1 * $PaddingPx
    y = -1 * $PaddingPx
    z = $shapeZ
    height = [double]$group.position.height + (2 * $PaddingPx)
    width = [double]$group.position.width + (2 * $PaddingPx)
}

$shape = [ordered]@{
    '$schema' = "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/2.10.0/schema.json"
    name = $ShapeId
    position = $shapePosition
    visual = [ordered]@{
        visualType = "shape"
        objects = [ordered]@{
            shape = @(
                [ordered]@{
                    properties = [ordered]@{
                        tileShape = [ordered]@{
                            expr = [ordered]@{
                                Literal = [ordered]@{
                                    Value = "'rectangle'"
                                }
                            }
                        }
                    }
                }
            )
            fill = @(
                [ordered]@{
                    properties = [ordered]@{
                        fillColor = [ordered]@{
                            solid = [ordered]@{
                                color = [ordered]@{
                                    expr = [ordered]@{
                                        ThemeDataColor = [ordered]@{
                                            ColorId = 2
                                            Percent = 0.6
                                        }
                                    }
                                }
                            }
                        }
                        transparency = [ordered]@{
                            expr = [ordered]@{
                                Literal = [ordered]@{
                                    Value = "100D"
                                }
                            }
                        }
                    }
                    selector = [ordered]@{
                        id = "default"
                    }
                }
            )
            outline = @(
                [ordered]@{
                    properties = [ordered]@{
                        show = [ordered]@{
                            expr = [ordered]@{
                                Literal = [ordered]@{
                                    Value = "true"
                                }
                            }
                        }
                        weight = [ordered]@{
                            expr = [ordered]@{
                                Literal = [ordered]@{
                                    Value = "1D"
                                }
                            }
                        }
                    }
                    selector = [ordered]@{
                        id = "default"
                    }
                }
            )
        }
        visualContainerObjects = [ordered]@{
            background = @(
                [ordered]@{
                    properties = [ordered]@{
                        show = [ordered]@{
                            expr = [ordered]@{
                                Literal = [ordered]@{
                                    Value = "false"
                                }
                            }
                        }
                    }
                }
            )
        }
        drillFilterOtherVisuals = $true
    }
    parentGroupName = $GroupId
    howCreated = "InsertVisualButton"
}

$shapeDir = Join-Path $visualsDir $ShapeId
New-Item -Path $shapeDir -ItemType Directory -Force | Out-Null
$shapeJsonPath = Join-Path $shapeDir "visual.json"

$shape | ConvertTo-Json -Depth 100 | Set-Content -Path $shapeJsonPath -Encoding UTF8
Write-Host "Created/updated shape border at: $shapeJsonPath"
Write-Host "ShapeId: $ShapeId"

if ($Reload.IsPresent) {
    powerbi-desktop reload
}
