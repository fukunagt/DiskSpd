$Results = New-Object -TypeName System.Collections.Generic.List[PSCustomObject]
#
# Parameters
# 
$FileSize = "8G"
$aryBlockSize = @("1K", "2K","4K", "8K", "16K", "32K", "64K", "128K", "256K", "512K", "1M", "2M", "4M", "8M", "16M", "32M", "64M", "128M", "256M", "512M")
# Number of threads
$Thread = 1
$Cache = "-Sh"
$TestFile = "M:\test.dat"
$DiskSpd = "C:\diskspd\diskspd.exe"
# -c: File size
# -b: Block size
# -t: Number of threads
$BaseCmd = "$DiskSpd -c$FileSize -b{0} -t$Thread $Cache -w100 -o1 -Rxml $TestFile"

$Output = "C:\Result"
$Logfile = Join-Path $Output "result-seq-md-sync.csv"
if((Test-Path $Output) -eq $false){ New-Item -ItemType directory -Path $Output}

#$Result = New-object -TypeName PSCustomObject | select Datetime,Path, Duration,ThreadCount,Pattern,Cache, BlockSize,ReadMBytes_sec,ReadIOPS,WriteMBytes_sec,WriteIOPS,ReadCmd,WriteCmd
$Result = New-object -TypeName PSCustomObject | select Datetime,Path,Thread,Cache,BlockSize,WriteMBytes_sec,WriteIOPS,WriteCmd

foreach($BlockSize in $aryBlockSize){
	Write-Output ($BaseCmd -f $BlockSize)
	$xml = [xml](Invoke-Expression ($BaseCmd -f $BlockSize))

    $Result.Datetime = Get-Date -Format G
    $Result.Path = $TestFile
    $Result.Thread = $Thread
    $Result.Cache = $Cache
    $Result.BlockSize = $BlockSize
    $Result.WriteMBytes_sec = [double](($xml.Results.TimeSpan.Thread.Target.WriteBytes | Measure-Object -Sum).Sum / $xml.Results.TimeSpan.TestTimeSeconds / [math]::Pow(1024,2))
    $Result.WriteIOPS = [double](($xml.Results.TimeSpan.Thread.Target.WriteCount | Measure-Object -Sum).Sum / $xml.Results.TimeSpan.TestTimeSeconds)
    $Result.WriteCmd = $BaseCmd -f $BlockSize
    Write-Output $Result | ft

    $Result | Export-CSV -Encoding Unicode -Path $Logfile -Append -NoTypeInformation

    $Results.Add($Result.psobject.copy()) > $null
}

#$Results | Out-GridView -Title "DiskSpd Result"
