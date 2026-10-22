param([string]$PackageName = 'CrocodiloInvaders-DEV-Windows.zip')
$ErrorActionPreference = 'Stop'
$buildsRoot = Join-Path (Split-Path $PSScriptRoot -Parent) 'Builds'
$buildRoot = Join-Path $buildsRoot 'Windows-DEV'
$packageRoot = Join-Path $buildsRoot 'Pacotes'
$executable = Join-Path $buildRoot 'CrocodiloInvaders.exe'
$assembly = Join-Path $buildRoot 'CrocodiloInvaders_Data/Managed/Assembly-CSharp.dll'
foreach ($required in @($executable, (Join-Path $buildRoot 'UnityPlayer.dll'), $assembly)) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Arquivo obrigatório ausente: $required" }
}
$assemblyText = [System.Text.Encoding]::UTF8.GetString([System.IO.File]::ReadAllBytes($assembly))
foreach ($type in @('DevelopmentCardSession','DevelopmentCardTest','DeveloperMenuView','CardRarityFeedback','ApplyCardSpacing','CelebrateChoice')) {
    if (-not $assemblyText.Contains($type)) { throw "Build sem o modo DEV atual: $type" }
}
$readme = @'
CROCODILO INVADERS - TESTE DAS CARTAS

1. Extraia TODOS os arquivos deste ZIP para uma pasta.
2. Abra CrocodiloInvaders.exe. Nao precisa instalar nem abrir a Unity.
3. No menu inicial, clique no pequeno DEV no canto superior direito ou pressione F8.
4. Escolha sorteio normal, raridade fixa ou ciclo das 25 cartas.
5. Clique INICIAR TESTE DE CARTAS e pressione ENTER quando o loading estiver pronto.
6. Escolha com mouse ou 1/2/3. R faz rerolls infinitos no modo DEV.
7. Depois de escolher, F8 abre o painel para gerar outra oferta, zerar bonus ou voltar ao menu.

As 25 cartas novas e as expressoes progressivas estao incluidas.
V13: textos sem glifos cortados e com mais margem, verso militar com selo do Croc
e quatro sons proprios de revelacao, da rara a mitica, com impacto crescente.
V14: abertura da arte e borda interna recompostas nas 25 cartas, sem tiras da
ilustracao antiga atras da moldura. Colecao inteira conferida no fluxo real.
V15: fundo externo transparente nas 25 frentes e no verso, sem retangulo preto
nos cantos e recortes externos das molduras.
Efeitos externos progressivos por raridade incluidos: faiscas azuis, energia roxa,
raios dourados e explosao carmesim com relampagos na mitica. Mais espaco entre cartas.
A carta mais rara revela por ultimo. Escolher uma carta dispara outro impacto.
Foils/holograficos dinamicos dentro da arte continuam para uma etapa posterior.
O teste usa a cena e os controladores reais e nao registra resultados no ranking.

Mantenha o EXE, UnityPlayer.dll, a pasta CrocodiloInvaders_Data e MonoBleedingEdge juntos.
'@
[System.IO.File]::WriteAllText((Join-Path $buildRoot 'LEIA-ME.txt'), $readme, [System.Text.UTF8Encoding]::new($false))
New-Item -ItemType Directory -Path $packageRoot -Force | Out-Null
$zipPath = Join-Path $packageRoot $PackageName
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
if (Test-Path -LiteralPath $zipPath) { throw "Pacote ja existe: $zipPath" }
$archive = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($file in Get-ChildItem -LiteralPath $buildRoot -File -Recurse) {
        $relative = $file.FullName.Substring($buildRoot.Length + 1)
        if ($relative -match '(?i)(DoNotShip|BackUpThisFolder|\.pdb$)') { continue }
        $entry = 'CrocodiloInvaders-DEV/' + $relative.Replace('\','/')
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $entry, [System.IO.Compression.CompressionLevel]::Fastest) | Out-Null
    }
} finally { $archive.Dispose() }
$check = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
try {
    foreach ($entry in @('CrocodiloInvaders.exe','UnityPlayer.dll','CrocodiloInvaders_Data/Managed/Assembly-CSharp.dll','LEIA-ME.txt')) {
        if ($null -eq $check.GetEntry('CrocodiloInvaders-DEV/' + $entry)) { throw "ZIP incompleto: $entry" }
    }
} finally { $check.Dispose() }
$hash = Get-FileHash -LiteralPath $zipPath -Algorithm SHA256
[System.IO.File]::WriteAllText((Join-Path $packageRoot 'SHA256SUMS.txt'), $hash.Hash.ToLowerInvariant() + '  ' + [System.IO.Path]::GetFileName($zipPath))
Get-Item -LiteralPath $zipPath | Select-Object FullName, Length
