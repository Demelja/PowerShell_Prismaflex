# Author: deemmel@gmail.com AKA Dee-Man
# 01/10/2021
# release 19/10/2021
#
# The script should be started inside a directory with packed log-file (BlaBlaBla.LOX). 
# Script action result is txt-file filled with MDB-MALFUNCTION records.
#
# The Magic is over there => ( $record_item[2] -match "64" )
# 8	EVENT
# 16	SET_VALUE
# 32	MDB_WARNING
# 64	MDB_MALFUNCTION
# 128	MDB_CAUTION
# 256	MDB_ADVISORY
#




#
# $PSScriptRoot - Contains the full path to the script that invoked the current command
# $ExtractPath - temporary directory for unpacking
# $ArchivePath - result file
$YearLogsPath = $PSScriptRoot
$ExtractPath = Join-Path $YearLogsPath "Temp"
$ArchiveFile = New-Item -Type File -Force -Path $YearLogsPath -Name "mdb_malfunction_alarms.txt"


# 
function Expand-Tar($tarFile, $dest) {

    if (-not (Get-Command Expand-7Zip -ErrorAction Ignore)) {
        Install-Package -Scope CurrentUser -Force 7Zip4PowerShell > $null
    }

    Expand-7Zip $tarFile $dest
}


$list_archive = Get-ChildItem -Path $YearLogsPath | Where-Object { $_.PSIsContainer -eq $false -and $_.Extension -eq '.LOX' } | Sort-Object -Property { $_.CreationTime } -Descending

## Write-Host "`n Total: " $list_archive.Count " files `n"

ForEach ( $arch in $list_archive ) { 

    New-Item -Type Directory -Force -Path $ExtractPath | Out-Null

    Expand-Tar $arch.FullName $ExtractPath

    $archive_lox = Get-ChildItem $ExtractPath | Where-Object { $_.PSIsContainer -eq $false -and $_.Extension -eq '.tar' }
    Expand-Tar $archive_lox.FullName $ExtractPath

    $list_log = Get-ChildItem $ExtractPath | Where-Object { $_.PSIsContainer -eq $false -and $_.Extension -ne '.tar' }

    ForEach ( $log in $list_log | Where-Object { $_.PSIsContainer -eq $false -and $_.Extension -eq '.ple' } ) { 

        $log.Name | Out-File -Append $ArchiveFile
        #$event_log = Get-ChildItem $ExtractPath | Where-Object { $_.PSIsContainer -eq $false -and $_.Extension -eq '.ple' }

        ForEach ( $record_line in Get-Content $log.FullName ) {
            
            $record_item = $record_line.Split( ";" )
            if ( $record_item[2] -match "64" ) {
                Write-Host $record_line
                $record_line | Out-File -Append $ArchiveFile
            }
            if ( ( $record_item[2] -match "32" ) -and ( ( $record_item[4] -match "95") -or ( $record_item[4] -match "94") -or ( $record_item[4] -match "93") -or ( $record_item[4] -match "92") -or ( $record_item[4] -match "91") -or ( $record_item[4] -match "90") -or ( $record_item[4] -match "97") -or ( $record_item[4] -match "99") -or ( $record_item[4] -match "75") -or ( $record_item[4] -match "85") -or ( $record_item[4] -match "8") -or ( $record_item[4] -match "1") ) ) {
                Write-Host $record_line
                $record_line | Out-File -Append $ArchiveFile
            }

        }
        
    }

    "--------" | Out-File -Append $ArchiveFile
    Remove-Item $ExtractPath -Force -Recurse

}