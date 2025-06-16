<#
.SYNOPSIS
    Tulostaa kansion puurakenteen ASCII-merkkeinä, näyttää tiedostokoot ja värikoodaa eri formaatit.
.PARAMETER RootPath
    Mistä kansiosta puurakenne aloitetaan. Oletuksena nykyinen työhakemisto (EXE:n kansio).
.PARAMETER SkipContentFolders
    Lista kansioiden nimistä, joiden sisältöä ei tulosteta (kansiot itse tulostuvat nimenä).
#>
Param(
    [string]   $RootPath           = '',
    [string[]] $SkipContentFolders = @()
)

# Jos Path annettu tyhjänä, ota työhakemisto (= EXE:n / skriptin kansio)
if ([string]::IsNullOrWhiteSpace($RootPath)) {
    $RootPath = (Get-Location).Path
}

# Poistetaan lopusta mahdollinen '\'
$RootPath = $RootPath.TrimEnd('\')

function Show-Tree {
    Param(
        [Parameter(Mandatory)][string]   $Path,
        [string]                         $Prefix             = '',
        [string[]]                       $SkipContentFolders = @()
    )

    # Hae ensin kansiot, sitten tiedostot
    $items = Get-ChildItem -LiteralPath $Path -Force |
             Sort-Object @{Expression={$_.PSIsContainer};Descending=$true}, Name

    for ($i = 0; $i -lt $items.Count; $i++) {
        $item   = $items[$i]
        $isLast = ($i -eq $items.Count - 1)

        if ($isLast) {
            $connector   = '+-- '
            $childPrefix = '    '
        } else {
            $connector   = '|-- '
            $childPrefix = '|   '
        }

        if ($item.PSIsContainer) {
            Write-Host ("{0}{1}{2}/" -f $Prefix, $connector, $item.Name) -ForegroundColor Green
            if (-not ($SkipContentFolders -contains $item.Name)) {
                Show-Tree `
                  -Path              $item.FullName `
                  -Prefix            ($Prefix + $childPrefix) `
                  -SkipContentFolders $SkipContentFolders
            }
        }
        else {
            $sizeKB = [Math]::Round($item.Length/1KB, 2)
            $ext    = $item.Extension.TrimStart('.').ToLower()
            switch ($ext) {
                'ps1' { $col='Yellow';   break }
                'py'  { $col='Cyan';     break }
                'txt' { $col='Gray';     break }
                'md'  { $col='DarkGray'; break }
                'pdf' { $col='Magenta';  break }
                default { $col='White';   break }
            }
            Write-Host ("{0}{1}{2} [{3}] ({4} KB)" -f 
                $Prefix, $connector, $item.Name, $ext, $sizeKB) -ForegroundColor $col
        }
    }
}

# Käynnistä
Show-Tree -Path $RootPath -SkipContentFolders $SkipContentFolders

# Pidä ikkuna auki tuplaklikkauksella
Write-Host
Write-Host 'Enter to Close…' -ForegroundColor Yellow
[void][System.Console]::ReadLine()
