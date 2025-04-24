# Disk Space Analyzer Script
# This script analyzes folder sizes on a specified path

param (
    [Parameter(Mandatory=$false)]
    [string]$Path = "C:\",
    
    [Parameter(Mandatory=$false)]
    [int]$TopItems = 20,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeFiles = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Recurse = $false
)

function Get-FolderSize {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FolderPath,
        
        [Parameter(Mandatory=$false)]
        [switch]$IncludeFiles,
        
        [Parameter(Mandatory=$false)]
        [switch]$Recurse
    )
    
    $items = @()
    
    # If path doesn't exist, return nothing
    if (-not (Test-Path -Path $FolderPath)) {
        Write-Warning "Path does not exist: $FolderPath"
        return $items
    }
    
    Write-Host "Analyzing path: $FolderPath" -ForegroundColor Cyan
    
    try {
        # Get all folders in the current path
        $folders = Get-ChildItem -Path $FolderPath -Directory -ErrorAction SilentlyContinue
        
        foreach ($folder in $folders) {
            $size = 0
            $fileCount = 0
            $folderCount = 0
            
            try {
                $childItems = Get-ChildItem -Path $folder.FullName -Recurse -ErrorAction SilentlyContinue
                $size = ($childItems | Where-Object { -not $_.PSIsContainer } | Measure-Object -Property Length -Sum).Sum
                $fileCount = ($childItems | Where-Object { -not $_.PSIsContainer } | Measure-Object).Count
                $folderCount = ($childItems | Where-Object { $_.PSIsContainer } | Measure-Object).Count
            }
            catch {
                Write-Warning "Error accessing $($folder.FullName): $($_.Exception.Message)"
            }
            
            $items += [PSCustomObject]@{
                Name = $folder.Name
                FullPath = $folder.FullName
                SizeBytes = $size
                SizeMB = [math]::Round($size / 1MB, 2)
                SizeGB = [math]::Round($size / 1GB, 2)
                FileCount = $fileCount
                FolderCount = $folderCount
                Type = "Directory"
            }
            
            # If recursion is enabled, scan subfolders too
            if ($Recurse) {
                $subitems = Get-FolderSize -FolderPath $folder.FullName -IncludeFiles:$IncludeFiles -Recurse:$Recurse
                $items += $subitems
            }
        }
        
        # If including files, get all files in the current path
        if ($IncludeFiles) {
            $files = Get-ChildItem -Path $FolderPath -File -ErrorAction SilentlyContinue
            
            foreach ($file in $files) {
                $items += [PSCustomObject]@{
                    Name = $file.Name
                    FullPath = $file.FullName
                    SizeBytes = $file.Length
                    SizeMB = [math]::Round($file.Length / 1MB, 2)
                    SizeGB = [math]::Round($file.Length / 1GB, 2)
                    FileCount = 1
                    FolderCount = 0
                    Type = "File"
                }
            }
        }
    }
    catch {
        Write-Warning "Error analyzing path $FolderPath`: $($_.Exception.Message)"
    }
    
    return $items
}

# Display a friendly intro
Write-Host "=======================================" -ForegroundColor Green
Write-Host "  DISK SPACE ANALYZER" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green
Write-Host "Target Path: $Path" -ForegroundColor Yellow
Write-Host "Include Files: $IncludeFiles" -ForegroundColor Yellow
Write-Host "Recursive Scan: $Recurse" -ForegroundColor Yellow
Write-Host "Showing Top: $TopItems items" -ForegroundColor Yellow
Write-Host "---------------------------------------" -ForegroundColor Green

# Get the initial drive info
$drive = Get-PSDrive -Name ($Path.Substring(0, 1))
$totalSize = $drive.Used + $drive.Free
$percentUsed = [math]::Round(($drive.Used / $totalSize) * 100, 2)

Write-Host "Drive $($drive.Name): Total: $([math]::Round($totalSize / 1GB, 2)) GB, Used: $([math]::Round($drive.Used / 1GB, 2)) GB ($percentUsed%), Free: $([math]::Round($drive.Free / 1GB, 2)) GB" -ForegroundColor Magenta
Write-Host "---------------------------------------" -ForegroundColor Green

# Get size information for folders
$results = Get-FolderSize -FolderPath $Path -IncludeFiles:$IncludeFiles -Recurse:$Recurse

# Output the results
Write-Host "Top $TopItems items by size:" -ForegroundColor Yellow
$results | Sort-Object -Property SizeBytes -Descending | Select-Object -First $TopItems | Format-Table -Property Name, @{Label="Size (GB)"; Expression={$_.SizeGB}}, @{Label="Size (MB)"; Expression={$_.SizeMB}}, FileCount, FolderCount, Type, FullPath -AutoSize

# Calculate the total size
$totalAnalyzedSize = ($results | Measure-Object -Property SizeBytes -Sum).Sum
$totalAnalyzedGB = [math]::Round($totalAnalyzedSize / 1GB, 2)
$totalItemCount = $results.Count

Write-Host "Total items analyzed: $totalItemCount, Combined size: $totalAnalyzedGB GB" -ForegroundColor Cyan

# Export to CSV if needed
$csvPath = Join-Path -Path $env:USERPROFILE -ChildPath "DiskAnalysis_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$results | Export-Csv -Path $csvPath -NoTypeInformation
Write-Host "Results exported to: $csvPath" -ForegroundColor Green
