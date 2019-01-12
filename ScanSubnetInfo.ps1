$ScriptFol = Split-Path -Parent $MyInvocation.MyCommand.Definition

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
Install-Parallel-Execution ;


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
                   WindowsVer = "null" ;
                   } ;
                   $content |  Export-Csv -Path $txtPath -Append -NoTypeInformation
                   Write-host "$comp is down" -ForegroundColor Red
              }Else
              {     
                   
                   $UserName =  (Get-WmiObject -Class win32_computersystem -ComputerName $comp).UserName ;
                   $CompModel = (Get-WmiObject -Class win32_computersystem -ComputerName $comp).Model ;
                   $WindowsVer = (Get-WmiObject -Class Win32_OperatingSystem -ComputerName $comp).BuildNumber ;
                   Start-Sleep -Seconds 1 ;
                         
                   $content = New-Object PSObject -Property @{   
                   ComputerName = $comp ;
                   UserName =  $UserName ;
                   CompModel = $CompModel ;
                   WindowsVer = $WindowsVer  ;
                   }
                   $content |  Export-Csv -Path $txtPath -Append -NoTypeInformation
                   Write-host "$comp,$UserName,$CompModel,$WindowsVer"  -ForegroundColor Green                                     
              }
                
     
     #return $ObjectArray ;
    
}
  [array]$output = @() ;

$ip=get-WmiObject Win32_NetworkAdapterConfiguration|Where {$_.Ipaddress.length -gt 1} 
$LocalHostIP = $ip.ipaddress[0] 
$IndexOfLastDot = $LocalHostIP.lastindexof(".") ;
$Network = $LocalHostIP.substring(0,$IndexOfLastDot) ;
$LocalNode = $LocalHostIP.substring($IndexOfLastDot+1) ;
[array]$Hosts = @() ;
for ( [int]$i = 15 ; $i -le 250 ; $i++ )
 {
    $Node = $Network + "." + $i ;
    $Hosts += $Node ;
 }
  $txtPath = "C:\TMP\tmp.csv"
  if (Test-Path $txtPath -ErrorAction 'SilentlyContinue' ){Remove-Item $txtPath ;} ;
  $Hosts | Start-Parallel -Scriptblock ${Function:\Get-UserMachineInfo} ;
  Get-Content $txtPath |  Out-GridView ;
  Invoke-Item $txtPath ;

  pause ;
