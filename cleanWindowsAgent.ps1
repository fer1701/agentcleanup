#$hostname = $env:COMPUTERNAME
Write-Host "Disk space big picture before cleanup:"
#Get-CimInstance -ClassName Win32_LogicalDisk | Select-Object -Property DeviceID, @{'Name' = 'Size (GB)'; Expression = { [int]($_.Size / 1GB) }},@{'Name' = 'FreeSpace (GB)'; Expression = { [int]($_.FreeSpace / 1GB) }}
Get-Volume -DriveLetter C

$path1 = "c:\wc"

if (Test-Path -path $path1){
    Write-Host "Collecting info about $path1"
    $size = Get-ChildItem -path $path1 -recurse | Measure-Object -Sum Length
    $info = "FileCount: " + $size.count.tostring() + " Size: " +[math]::Round(($size.Sum / 1GB),2).ToString() + " GB"
    Write-Host $info
    Get-ChildItem $path1 -force
    #Get-ChildItem "c:\wc" -force
    Remove-Item -Path $path1 -force -recurse
    mkdir $path1
}

$path2 = "C:\Users\dgenrich_auto\.m2\repository\com\e2open\e2open"

if (Test-Path -path $path2){
    Write-Host "Collecting info about $path2"
    $size = Get-ChildItem -path $path2 -recurse | Measure-Object -Sum Length
    $info = "FileCount: " + $size.count.tostring() + "Size: " +[math]::Round(($size.Sum / 1GB),2).ToString() + " GB"
    Write-Host $info
    Get-ChildItem $path2 -force
    Remove-Item -Path $path2 -force -recurse
    mkdir $path2
}

$path3 = "C:\Maven\apache-maven-3.0.4"

if (Test-Path -path $path3){
    Write-Host "Collecting info about $path3"
    $size = Get-ChildItem -path $path3 -recurse | Measure-Object -Sum Length
    $info = "FileCount: " + $size.count.tostring() + "Size: " +[math]::Round(($size.Sum / 1GB),2).ToString() + " GB"
    Write-Host $info
    Get-ChildItem $path3 -force
    #Remove-Item -Path $path3 -force -recurse -Include *[0..9]*
    Get-Childitem -path $path3 -Directory -Include *[0-9]* -recurse -force | remove-item -force -recurse
}

Write-Host "Disk space big picture after cleanup:"
Get-Volume -DriveLetter C