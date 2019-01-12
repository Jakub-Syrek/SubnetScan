$ScriptFol = Split-Path -Parent $MyInvocation.MyCommand.Definition

$stopwatch =  [system.diagnostics.stopwatch]::StartNew()



function Restart-PowerShell-Elevated
{
   $Script = $ScriptFol + "\ScanSubnetInfo.ps1"
   $ConfirmPreference = “None”
   If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
    {   
     $arguments = " -ExecutionPolicy UnRestricted  & '" + $Script + "'" 
     Start-Process "$psHome\powershell.exe" -Verb "runAs" -ArgumentList $arguments
     Break
    }
}

function Install-Parallel-Execution
  {
    [bool]$tr = [Downloader]::new().CheckIfPathExists("C:\TMP") ;
   if ($tr )
    {
    }
    else
    {
    Restart-PowerShell-Elevated ;
    New-Item -ItemType directory -Path C:\TMP
    } ;

   
   if (Get-Module -ListAvailable -Name Start-parallel) 
     {
      

       Write-Host "Start-parallel Module exists" ;
     } 
   else 
     {
       Write-Host "Module does not exist" ;
       Restart-PowerShell-Elevated ;
       Install-Module -Name Start-parallel -Force ;
     }
  }








function Get-UserMachineInfo
 {
     [CmdletBinding()]
     param
     (
         [string]$comp 
         
     )
          $txtPath = "C:\TMP\tmp.csv"
          
     
          $ErrorActionPreference =  'SilentlyContinue' ;
          if (-not (Test-Connection -comp $comp -quiet))
              {
                   $content = New-Object PSObject -Property @{   
                   ComputerName = $comp ;
                   UserName = "null" ;
                   CompModel = "null" ;
                   WindowsBuild = "null" ;
                   WindowsVer = "null" ;
                   } ;
                   $content |  Export-Csv -Path $txtPath -Append -NoTypeInformation
                   Write-Prompt "$comp is down" -ForegroundColor Red
              }Else
              {     
                   
                   $UserName =  (Get-WmiObject -Class win32_computersystem -ComputerName $comp).UserName ;
                   $CompModel = (Get-WmiObject -Class win32_computersystem -ComputerName $comp).Model ;
                   $WindowsBuild = (Get-WmiObject -Class Win32_OperatingSystem -ComputerName $comp).BuildNumber ;
                   $WindowsVersion = (Get-WmiObject -Class Win32_OperatingSystem -ComputerName $comp).version
                   Start-Sleep -Seconds 1 ;
                         
                   $content = New-Object PSObject -Property @{   
                   ComputerName = $comp ;
                   UserName =  $UserName ;
                   CompModel = $CompModel ;
                   WindowsBuild = $WindowsBuild ;
                   WindowsVer = $WindowsVersion  ;
                   }
                   $content |  Export-Csv -Path $txtPath -Append -NoTypeInformation
                   Write-Prompt "$comp,$UserName,$CompModel,$WindowsVer"  -ForegroundColor Green                                     
              }         
}
  
Function Get-My-Ips
   {
     $ip=get-WmiObject Win32_NetworkAdapterConfiguration|Where {$_.Ipaddress.length -gt 1} ;
     return $ip ;
   }


Function Build-Source-array
{
param
([int]$min , [int]$max)
[array]$Hosts = @() ;
for ( [int]$i = $min ; $i -le $max ; $i++ )
 {
    $Node = $Network + "." + $i ;
    $Hosts += $Node ;
 }
 return $Hosts ;
 }
  
   Install-Parallel-Execution ;
   $myIPs = Get-My-Ips ;
   $myIP = $myIPs.ipaddress[0] ;
   $IndexOfLastDot = $myIP.lastindexof(".") ;
   $Network = $myIP.substring(0,$IndexOfLastDot) ;
   $LocalNode = $myIP.substring($IndexOfLastDot+1) ;
   [array]$Hosts = Build-Source-array "15" "250" ;
   $txtPath = "C:\TMP\tmp.csv" ;
   if (Test-Path $txtPath -IsValid )
      {Remove-Item $txtPath ;} ;
   
   $Hosts | Start-Parallel -Scriptblock ${Function:\Get-UserMachineInfo} ;
   
   Get-Content $txtPath |  Out-GridView ;
   Invoke-Item $txtPath ;
   Write-Host "All threads returned in :" $StopWatch.Elapsed.ToString() ;
   Pause ;
 
