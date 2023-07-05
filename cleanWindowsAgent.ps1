 <#
    .SYNOPSIS
    Deletes a specific file or folder(s) on the requested windows remote computer(s). 
    
    .DESCRIPTION
    This script can be used to remove the content of the specified folder(s) on the targeted windows remote computer(s). 
    Also, it can be used to delete a specific file on the targeted computer(s).

    .PARAMETER FolderPath
    Specifies the path of the folder(s) to be deleted. ** MANDATORY **

    .PARAMETER ComputerName
    Specifies the name of the computer(s) on which this script will run. The default is the local computer.  ** OPTIONAL **

    .PARAMETER DeleteFile
    Specifies to delete a predefined file "C:\Users\dgenrich_auto\AppData\Local\Temp\bamboo-ssh*.bat" in Bamboo Windows agents.  ** MANDATORY **

    .INPUTS
    None. 

    .OUTPUTS
    None. 

    .EXAMPLE
    .\cleanwinagents.ps1 -FolderPath "c:\wc"
    This example deletes the content of the folder "c:\wc" on the local computer where the script is executed.

    .EXAMPLE
    .\cleanwinagents.ps1 -ComputerName "bld-win-srv028.dev.e2open.com" -FolderPath "c:\wc"
    This example deletes the content of the folder "c:\wc" on the computer "bld-win-srv028.dev.e2open.com".

    .EXAMPLE
    .\cleanwinagents.ps1 -ComputerName "bld-win-srv028.dev.e2open.com" -FolderPath "c:\wc","c:\Maven\apache-maven-3.0.4"
    This example deletes the content of the folder "c:\wc" and only the folders whose names are made by only numbers inside  "c:\Maven\apache-maven-3.0.4"  on the computer "bld-win-srv028.dev.e2open.com".

    .EXAMPLE
    .\cleanwinagents.ps1 -ComputerName "bld-win-srv028.dev.e2open.com","bld-win-srv030.dev.e2open.com" -FolderPath "c:\wc" 
    This example deletes the content of the folder "c:\wc" on the computers "bld-win-srv028.dev.e2open.com"and "bld-win-srv030.dev.e2open.com".

    .EXAMPLE
    .\cleanwinagents.ps1 -ComputerName "bld-win-srv028.dev.e2open.com","bld-win-srv030.dev.e2open.com" -FolderPath "c:\wc","c:\Maven\apache-maven-3.0.4"
    This example deletes the content of the folder "c:\wc" and "c:\Maven\apache-maven-3.0.4" on the computers "bld-win-srv028.dev.e2open.com"and "bld-win-srv030.dev.e2open.com".

    .EXAMPLE
    .\cleanwinagents.ps1 -ComputerName "bld-win-srv028.dev.e2open.com" -DeleteFile
    This example deletes the file "C:\Users\dgenrich_auto\AppData\Local\Temp\bamboo-ssh*.bat" on the computers "bld-win-srv028.dev.e2open.com".
    
    .EXAMPLE
    .\cleanwinagents.ps1 -ComputerName "bld-win-srv028.dev.e2open.com","bld-win-srv030.dev.e2open.com" -DeleteFile
    This example deletes the file "C:\Users\dgenrich_auto\AppData\Local\Temp\bamboo-ssh*.bat" on the computers "bld-win-srv028.dev.e2open.com" and "bld-win-srv030.dev.e2open.com".
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByFolder')]
    Param
    (
        [Parameter(Mandatory=$true, Position=1, ParameterSetName = "ByFolder")]
        [ValidateCount(0, 5)]
        [ValidatePattern('^C:\\')]
        [string[]] $FolderPath = @(),
    
        [Parameter(Mandatory=$true, Position=1, ParameterSetName = "ByFile")]
        [switch] $DeleteFile = $false,
    
        [Parameter(Mandatory=$false, Position=2)]
        [ValidateCount(1, 5)]
        [ValidateScript({
            if (Test-Connection $_ -Count 3) { return $true}
            throw (Write-Host "'$_' is not a valid server or is offline" -ForegroundColor yellow)
            })]
        [string[]] $ComputerName = @()      
     )       
    
    function get-volumeinfo ()
    {
        [cmdletbinding()]
        Param (
            [ValidateNotNullorEmpty()]
            [string]$Drive="C:",
            [ValidateNotNullorEmpty()]
            [string]$Computername = $env:computername
        )
    
        Get-WmiObject -Class Win32_LogicalDisk -filter "DeviceID='$Drive'" -ComputerName $Computername |
        Select-object @{Name="Computername";Expression={$_.SystemName}},
        @{Name="OS";Expression={ (Get-WmiObject -class win32_operatingSystem -ComputerName $computername).caption}},
        DeviceID,VolumeName,
        @{Name="SizeGB";Expression={[int]($_.size/1gb)}},
        @{Name="FreeGB";Expression={ [math]::Round($_.freespace/1gb,2)}},
        @{Name="PctFree";Expression={ [math]::Round(($_.freespace/$_.size)*100,2)}}
    }
    
    function remove-directory ()
    {
        [CmdletBinding()]
        Param
        (              
            [Parameter(Mandatory=$false, Position=1, ParameterSetName = "ByFolder")]
            [ValidateCount(0, 5)]
            [ValidatePattern('^C:\\')]
            [ValidateScript({
                if (Test-Path $_) 
                { return $true}
                throw (Write-Host "'$_' is not a valid directory" -ForegroundColor yellow)
                })]
            [string[]] $DirectoryPath = @()
        )       
              
        #$MavenCachePath = "C:\Maven\apache-maven-3.0.4"
        $MavenCachePath = "C:\Testfolder\apache-maven-3.0.4"
        
        Write-Output "*******************************************"
        Write-Output "*  Disk space big picture before cleanup  *"
        Write-Output "*******************************************"
        get-volumeinfo
        
        foreach ($Directory in $DirectoryPath) 
        {   
            Get-ChildItem $Directory | Format-Table
            Write-Output "*******************************************"
            Write-Output "Collecting info about" $Directory
            $size = Get-ChildItem -path $Directory -recurse | Measure-Object -Sum Length
            $info = "FileCount: " + $size.count.tostring() + " Size: " +[math]::Round(($size.Sum / 1GB),2).ToString() + " GB"
            Write-Output $info                                
            Write-Output "*******************************************"
    
            if (Test-Path -path $Directory) 
            {
                if ($Directory -eq $MavenCachePath)
                {
                    Write-Output "Cleaning $($Directory)..."
                    Get-Childitem -path $MavenCachePath -Directory -Include *[0-9]* -recurse -force | remove-item -force -recurse 
                }
                else
                {
                    Write-Output "Cleaning $($Directory)..."
                    Remove-Item -Path $Directory -force -recurse
                    mkdir $Directory              
                }          
            }              
        }
        Write-Output "******************************************"
        Write-Output "*  Disk space big picture after cleanup  *"
        Write-Output "******************************************"
        get-volumeinfo
        
    }
    

    switch ($PSCmdlet.ParameterSetName) {
       
        ByFile
        {
            $FileToDelete = "C:\Users\dgenrich_auto\AppData\Local\Temp\bamboo-ssh*.bat"
            $BambooAgentPath = "C:\Agent\agent.bat"
            $credentials = Get-Credential e2hq\dgenrich_auto

            foreach ($Computer in $ComputerName)
            {
               # Invoke-Command -ComputerName $Computer -credential $credentials -Scriptblock { $using:FileToDelete, $using:BambooAgentPath 
                    if (Test-Path -path $using:FileToDelete)
                    {         
                        get-process | where-object {$_.MainWindowTitle -eq "agent.bat"} | stop-process
                        Write-Output "Deleting the file $($using:FileToDelete)"
                        Write-Output $using:FileToDelete
                        Remove-Item -Path $using:FileToDelete -Force
                        Write-Output "Starting the Bamboo agent"
                        Start-Process -FilePath $using:BambooAgentPath                        
                    }
                    else
                    {
                        Write-Host "File $($using:FileToDelete) does not exist" -ForegroundColor yellow
                    }
               # } 
            }
        }
     
        ByFolder
        {
            if (($ComputerName.count -gt 0) -and ($FolderPath.count -gt 0)) 
            {
                $credentials = Get-Credential e2hq\dgenrich_auto
                foreach ($Computer in $ComputerName)
                {        
                    Invoke-Command -FilePath \\bld-win-srv022.dev.e2open.com\sharedfolder\cleanwinagents.ps1 -argumentlist (,$FolderPath) -ComputerName $Computer -credential $credentials
                }  
            }
    
            elseif ($ComputerName.count -gt 0) 
            {
                $credentials = Get-Credential e2hq\dgenrich_auto
                foreach ($Computer in $ComputerName)
                {        
                    Invoke-Command -FilePath \\bld-win-srv022.dev.e2open.com\sharedfolder\cleanwinagents.ps1 -ComputerName $Computer -credential $credentials
                }   
            }
    
            elseif ($FolderPath.count -gt 0)
            {
                remove-directory $FolderPath
            }
        }   
    }
    
    
