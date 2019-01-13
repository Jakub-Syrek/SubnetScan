$ScriptFol = Split-Path -Parent $MyInvocation.MyCommand.Definition

$stopwatch =  [system.diagnostics.stopwatch]::StartNew()
Add-Type -AssemblyName PresentationFramework
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
  
[xml]$XAMLWindow = '
<Window 
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Height="Auto"
    SizeToContent="WidthAndHeight"
    Title="Get-Info-From-Subnet">
    <ScrollViewer Padding="10,10,10,0" ScrollViewer.VerticalScrollBarVisibility="Disabled">
        <StackPanel>
            <StackPanel Orientation="Horizontal">
                <Label Margin="10,10,0,10">Subnet:</Label>
                <TextBox Name="Input" Margin="10" Width="250px"></TextBox>
            </StackPanel>
            <DockPanel>
                <Button Name="ButtonGetService" Content="Get-Info" Margin="10" Width="150px" IsEnabled="false"/>
                <Button Name="ButtonClose" Content="Close" HorizontalAlignment="Right" Margin="10" Width="50px"/>
            </DockPanel>
        </StackPanel> 
    </ScrollViewer >
</Window>
'

# Create the Window Object
$Reader=(New-Object System.Xml.XmlNodeReader $XAMLWindow)
$Window=[Windows.Markup.XamlReader]::Load( $Reader )

    # TextChanged Event Handler for Input 
    $TextboxInput = $Window.FindName("Input")
    $TextboxInput.add_TextChanged.Invoke({
    $Network = $TextboxInput.Text
    $ButtonGetService.IsEnabled = $Hosts -ne ''
})

    # Click Event Handler for ButtonClose
    $ButtonClose = $Window.FindName("ButtonClose")
    $ButtonClose.add_Click.Invoke({
    $Window.Close();
})

    # Click Event Handler for ButtonGetService
    $ButtonGetService = $Window.FindName("ButtonGetService")
    $ButtonGetService.add_Click.Invoke({
    $Network = $TextboxInput.text.Trim()
    try{
         [array]$Hosts = Build-Source-array "15" "250" ;
         $Hosts | Start-Parallel -Scriptblock ${Function:\Get-UserMachineInfo} ; 
         Get-Content $txtPath |  Out-GridView ;
         Invoke-Item $txtPath ;
         Write-Host "All threads returned in :" $StopWatch.Elapsed.ToString() ;              
    }catch{
        [System.Windows.MessageBox]::Show($_.exception.message,"Error",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error)
    }
})



  
   Install-Parallel-Execution ;
   $myIPs = Get-My-Ips ;
   $myIP = $myIPs.ipaddress[0] ;
   $IndexOfLastDot = $myIP.lastindexof(".") ;
   $Network = $myIP.substring(0,$IndexOfLastDot) ;

   
   $txtPath = "C:\TMP\tmp.csv" ;
   if ([downloader]::new().CheckIfPathExists($txtPath))
      {Remove-Item $txtPath ;} ;
   # Open the Window
   $Window.ShowDialog() | Out-Null
   
   
   
 
