Write-Host "Hang tight, evaluating, locating, and expandin if present..."
#Gather data and evaluate potenital sucess rate
[string]$nfo = reagentc /info

#Verify if WINRE is enabled, if so proceed and assign identified disk to $disk.
if($nfo -match ".*Windows RE status:.*Enabled.*"){ 
  #Locate the disk number winre partition has been installed to.
  $nfo -match ".*Windows RE location.*harddisk(\d+)" | Out-Null 
    $disk = $Matches[1]
  #Locate the partition winre is on.  
  $nfo -match ".*Windows RE location.*partition(\d+)" | Out-Null 
    $partition = $Matches[1]
  #gpt or mbr eval.  
  $disk_type = $(Get-Disk | Select-Object Number, PartitionStyle | ?{$_.Number -eq 0}).PartitionStyle 
  
#Start building the script with variables to pass to diskpart following Microsoft's process to expand recovery partition:  
  #Target disk that contains the recovery partition.
  $Diskpart_Script =  "sel disk $disk`n" 
  #Target partition left adjacent to recovery partition, OS partition that has extra space  
  $Diskpart_Script += "sel part $($partition - 1)`n" 
  #Shrink partition by 755m.
  $Diskpart_Script += "shrink desired=750 minimum=600`n" 
  $Diskpart_Script += "sel part $partition`n" 
  #Remove oringinal.. I know, I know here comes the pucker factor stage of process ;)
  $Diskpart_Script += "delete partition override`n" 
  #Recreate partition based on gpt or mbr.
  if ($disk_type -eq 'GPT'){ 
    $Diskpart_Script += "create partition primary id=de94bba4-06d1-4d40-a16a-bfd50179d6ac`n"
    $Diskpart_Script += "gpt attributes=0x8000000000000001`n"
  }else{
    $Diskpart_Script += "create partition primary id=27`n"
  }
  #Format new raw partition.
  $Diskpart_Script += "format fs=ntfs label=`"Windows RE tools`" quick`n" 
  #Create the actual work process variable with above info and pipe to RecPartExpansion.txt.
  $Diskpart_Script | Out-File .\RecPartExpansion.txt -Encoding ascii 
  
#Actual work now being executed here....
  reagentc /disable
  diskpart /s .\RecPartExpansion.txt
  reagentc /enable
  Write-Host "Recovery Partition has been expanded. Please review logs to verify process was sucessful"
}