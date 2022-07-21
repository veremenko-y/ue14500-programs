$curPath = Get-Location
$env:path += ";$curPath\cc65\"
$programsOutPath = "out"

"# Compiling UE14500 programs"
Remove-Item "${programsOutPath}/*"
$programs = Get-ChildItem "*.s" | Select-Object -ExpandProperty Name

foreach ($program in $programs)
{    
    $p = [System.IO.Path]::GetFileNameWithoutExtension($program)
    "Compiling $p"
    Invoke-Expression "ca65 -g $p.s -o ${programsOutPath}/$p.o -l ${programsOutPath}/$p.lst --list-bytes 0"
    Invoke-Expression "ld65 -o ${programsOutPath}/$p.bin -Ln ${programsOutPath}/$p.labels -m ${programsOutPath}/$p.map -C sdk/ue14500.cfg ${programsOutPath}/$p.o"
}

"DONE"