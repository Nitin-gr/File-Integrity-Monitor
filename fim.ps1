Function Calculate-File-Hash($filepath) {
    $filepath = Get-FileHash -Path $filepath -Algorithm SHA512
    return $filepath
}

Function Erase-Baseline-IfAlready-Exists() {
    $baslineExists = Test-Path -Path .\baseline.txt

    if($baslineExists){
        #Delete it 
        Remove-Item -Path .\baseline.txt
    }
}

Write-Host ""
Write-Host "What would you like to do?"
Write-Host "     1) Collect new baseline?"
Write-Host "     2) Begin monitoring files with saved baseline?"
$response = Read-Host -Prompt "Please enter 1 or 2"
Write-Host ""

if ($response -eq 1){
    #delte the baseline.txt file if it already exists
    Erase-Baseline-IfAlready-Exists

    #get the path of the file
    $targetFilePath = Read-Host -Prompt "Enter the complete/full file path to target"
    
    #check whether the entered path is valid or invalid
    $pathValidity = Test-Path -Path $targetFilePath
    
    if($pathValidity){
         #calculate the hash of the target files and store it in the baseline.txt file

        #collect all files in the target files in recursive
        $files = Get-ChildItem -Path $targetFilePath -File -Recurse -Force

        #calculate the hash of each file and write it to the baseline.txt
        foreach($f in $files){
            $hash = Calculate-File-Hash $f.FullName 
            "$($hash.Path)`t$($hash.Hash)" | Out-File -FilePath .\baseline.txt -Append
        }
    }
    else{
        #the path is invalid, so notify the user
        Write-Host "Enter a valid path..." -ForegroundColor Red
    } 

   
}
elseif ($response -eq 2){

    $fileHashDictionary = @{}
   
    
    #load the file hash from baseline.txt and store them in a dictionary
    $filePathAndHash = Get-Content -Path .\baseline.txt
    
    foreach($f in $filePathAndHash){
        $fileHashDictionary.add($f.Split("`t")[0], $f.Split("`t")[1])
    }
    
    
    #begining the continous monitoring of the files from the baseline.txt file
    while($true){
        Start-Sleep -Seconds 2

        $files = Get-ChildItem -Path $targetFilePath -File -Recurse -Force

        #calculate the hash of each file and write it to the baseline.txt
        foreach($f in $files){
            $hash = Calculate-File-Hash $f.FullName 
            #"$($hash.Path)|$($hash.Hash)" | Out-File -FilePath .\baseline.txt -Append
            
            if($fileHashDictionary[$hash.Path] -eq $null){
                #a new file hash been created!
                Write-Host "$($hash.Path) has been created by $((whoami).split("\")[1]) at $(Get-Date -Format "dddd MM/dd/yyyy HH:mm")" -ForegroundColor Green 
            }
            else{
                
                if($fileHashDictionary[$hash.Path] -eq $hash.Hash){
                    #the file has not changed 
                }
                else{
                    #file has been compromised..
                    Write-Host "$($hash.Path) has been changed by $((whoami).split("\")[1]) at $(Get-Date -Format "dddd MM/dd/yyyy HH:mm")" -ForegroundColor Yellow
                }
            }

        }

        foreach($key in $fileHashDictionary.Keys){
            $baselineFileStillExists = Test-Path -Path $key
            if(-Not $baselineFileStillExists){
                #one of the file must have been delete
                Write-Host "$($key) has been deleted by $((whoami).split("\")[1]) at $(Get-Date -Format "dddd MM/dd/yyyy HH:mm")" -ForegroundColor Red
            }
        }
    }
}