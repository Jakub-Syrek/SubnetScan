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

#$LocalHostIP = (Get-NetIPAddress -InterfaceAlias 'Local Area Connection* 10').IPAddress[1] ;
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
  #$Hosts = ( 'xxx' , 'xxx', 'xxx' ) ;
 
  #$output += (Get-UserMachineInfo -HostsListArr $Hosts ) ;
  $Hosts | Start-Parallel -Scriptblock ${Function:\Get-UserMachineInfo} 
  $txtPath = "C:\TMP\tmp.csv"
  Get-Content $txtPath |  Out-GridView ;

<#
  $output[0].ComputerName ;
  $output[1].ComputerName ;
  $output[2].UserName ;
  $output[2].CompModel ;
  $output[2].WindowsVer ;
  $output | Out-GridView ;
  #>
  #Env:\USERPROFILE\tmp.txt