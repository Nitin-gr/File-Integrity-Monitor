Function Calculate-File-Hash($filepath) {
    $filepath = Get-FileHash -Path $filepath -Algorithm SHA512
    return $filepath
}

Function Erase-Baseline-IfAlready-Exists() {
    $baslineExists = Test-Path -Path .\baseline.txt

    if($baslineExists){
        #Erase the content in it
        Clear-Content -Path .\baseline.txt
    }
}

while ($True){

Write-Host ""
Write-Host "What would you like to do?"
Write-Host "     1) Collect new baseline?"
Write-Host "     2) Begin monitoring files with saved baseline?"
Write-Host "     3) Exit"
$response = Read-Host -Prompt "Please enter your choice: "
Write-Host ""

switch($response){

    1 {
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

    2 {

    $fileHashDictionary = @{}

    #load the file hash from baseline.txt and store them in a dictionary
    $filePathAndHash = Get-Content -Path .\baseline.txt

    foreach($f in $filePathAndHash){
        $fileHashDictionary.add($f.Split("`t")[0], $f.Split("`t")[1])
    }

    #$fileHashDictionary


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
                $fileHashDictionary[$hash.Path] = $hash.Hash
            }
            else{

                if($fileHashDictionary[$hash.Path] -ne $hash.Hash){
                    #file has been compromised..
                    Write-Host "$($hash.Path) has been changed by $((whoami).split("\")[1]) at $(Get-Date -Format "dddd MM/dd/yyyy HH:mm")" -ForegroundColor Yellow
                    $fileHashDictionary[$hash.Path] = $hash.Hash
                }
            }

        }

        $keysToRemove = @()
        foreach($key in $fileHashDictionary.Keys){
            if (-not (Test-Path -Path $key)) {
            # File has been deleted
            Write-Host "$($key) has been deleted by $((whoami).split("\")[1]) at $(Get-Date -Format "dddd MM/dd/yyyy HH:mm")" -ForegroundColor Red
            $keysToRemove += $key
            }
        }

        # Remove the keys of deleted files from the dictionary
        foreach ($keyToRemove in $keysToRemove) {
            $fileHashDictionary.Remove($keyToRemove)
        }
    }
}

    3 {
        #exiting the program
        break

    }

    default {
        #enter the valid choice
        Write-Host "Enter a valid operation"
    }
}

}
