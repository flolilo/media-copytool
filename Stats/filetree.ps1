#requires -version 3
# Builds a file-tree, much like the classic "tree"-command.

param([string]$InPath)

#DEFINITION: Hopefully avoiding errors by wrong encoding now:
$OutputEncoding = New-Object -typename System.Text.UTF8Encoding


$rootpath = Get-ChildItem -Path $InPath -Directory | ForEach-Object {
    [PSCustomObject]@{
        FullName = $_.FullName
        BaseName = $_.BaseName
        Subfolder = @(Get-ChildItem -Path $_.FullName -Directory | ForEach-Object {
            [PSCustomObject]@{
                files = @(Get-ChildItem -Path $_.FullName -File -Recurse | ForEach-Object {
                    [PSCustomObject]@{
                        FullName = $_.FullName
                        Name = $_.Name
                        Extension = $_.Extension
                        Length = [math]::round(($_.Length / 1kB),3)
                    }
                })
                FullName = $_.FullName
                BaseName = $_.BaseName
            }
        })
        files = @(Get-ChildItem -Path $_.FullName -File | ForEach-Object {
            [PSCustomObject]@{
                FullName = $_.FullName
                BaseName = $_.BaseName
                Extension = $_.Extension
                Length = [math]::round(($_.Length / 1kB),3)
            }
        })
    }
}
$rootpath = $rootpath | Sort-Object -Property FullName
$rootpath | Out-Null
for($i=0; $i -lt $rootpath.Length; $i++){
    $rootpath[$i] = $rootpath[$i] | Sort-Object -Property FullName
    $rootpath | Out-Null
}
for($i=0; $i -lt $rootpath.Length; $i++){
    for($j=0; $i -lt $rootpath[$i].Length; $j++){
        $rootpath[$i].Subfolder[$j] = $rootpath[$i].Subfolder[$j] | Sort-Object -Property FullName
        $rootpath | Out-Null
    }
}

for($i=0; $i -lt $rootpath.Length; $i++){
    Write-Output $rootpath[$i].BaseName | Tee-Object -FilePath R:\test.txt -Append
    foreach($j in $rootpath[$i].Subfolder){
        Write-Output "    |---- $($j.BaseName)" | Tee-Object -FilePath R:\test.txt -Append
        foreach($k in $j.files){
            Write-Output "        |---- $($k.Extension)`t`t$($k.Length) kB" | Tee-Object -FilePath R:\test.txt -Append
        }
    }
    foreach($j in $rootpath[$i].files){
        Write-Output "    |---- $($j.Extension)`t`t`t$($j.Length) kB" | Tee-Object -FilePath R:\test.txt -Append
    }
}
