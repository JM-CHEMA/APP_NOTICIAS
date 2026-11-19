# DAL-M4 - Ajuste de imports después de mover archivos.
# Solo modifica directivas import/export; conserva la lógica y los comentarios.
# Crea copias de los archivos modificados fuera del proyecto.
$ErrorActionPreference = 'Stop'

$raiz = (Get-Location).Path
$pubspec = Join-Path $raiz 'pubspec.yaml'
if (-not (Test-Path -LiteralPath $pubspec)) {
    throw 'Abre PowerShell en la carpeta raiz de app_noticias (donde esta pubspec.yaml).'
}
$textoPubspec = [System.IO.File]::ReadAllText($pubspec)
if ($textoPubspec -notmatch '(?m)^name:\s*app_noticias\s*$') {
    throw 'Este script esta preparado para el proyecto app_noticias. No se hizo ningun cambio.'
}

$lib = Join-Path $raiz 'lib'
$radioOriginal = Join-Path (Split-Path -Parent $raiz) 'radio_app\lib'
$extras = @(
    @{ origen = 'app_theme.dart'; destino = 'modules\radio\radio_theme.dart' },
    @{ origen = 'helpers\constants.dart'; destino = 'modules\radio\radio_constants.dart' },
    @{ origen = 'helpers\utils.dart'; destino = 'modules\radio\radio_utils.dart' }
)

# Se copian archivos propios de radio con un nombre que evita pisar los de noticias.
foreach ($extra in $extras) {
    $origen = Join-Path $radioOriginal $extra.origen
    $destino = Join-Path $lib $extra.destino
    if (-not (Test-Path -LiteralPath $destino)) {
        if (Test-Path -LiteralPath $origen) {
            $directorio = Split-Path -Parent $destino
            if (-not (Test-Path -LiteralPath $directorio)) {
                New-Item -ItemType Directory -Path $directorio -Force | Out-Null
            }
            Copy-Item -LiteralPath $origen -Destination $destino
            Write-Host "Copiado: $($extra.destino)"
        }
        else {
            Write-Warning "Falta el archivo original: $origen"
        }
    }
}

$archivosLib = @(Get-ChildItem -LiteralPath $lib -Recurse -File -Filter '*.dart')
$archivos = @($archivosLib)
$test = Join-Path $raiz 'test'
if (Test-Path -LiteralPath $test) {
    $archivos += @(Get-ChildItem -LiteralPath $test -Recurse -File -Filter '*.dart')
}

$regexImports = [regex]@'
(?m)^(?<antes>[ \t]*(?:import|export)[ \t]+['"])(?<uri>[^'"]+)(?<despues>['"])
'@
$carpetaBackup = Join-Path $env:TEMP ('dal_m4_imports_backup_' + (Get-Date -Format 'yyyyMMdd_HHmmss'))
$encodingUtf8 = New-Object System.Text.UTF8Encoding($false)
$script:totalCambios = 0
$script:totalArchivos = 0
$script:pendientes = New-Object 'System.Collections.Generic.List[string]'

foreach ($archivo in $archivos) {
    $contenido = [System.IO.File]::ReadAllText($archivo.FullName)
    $actualizado = $regexImports.Replace($contenido, [System.Text.RegularExpressions.MatchEvaluator] {
            param($coincidencia)
            $uri = $coincidencia.Groups['uri'].Value
            if ($uri.StartsWith('dart:')) { return $coincidencia.Value }
            if ($uri.StartsWith('package:') -and
                -not $uri.StartsWith('package:radio_app/') -and
                -not $uri.StartsWith('package:app_noticias/')) {
                return $coincidencia.Value
            }

            # Deja intactos los imports internos que ya apuntan a un archivo real.
            if ($uri.StartsWith('package:app_noticias/')) {
                $rutaActual = Join-Path $lib ($uri.Substring('package:app_noticias/'.Length).Replace('/', '\'))
                if (Test-Path -LiteralPath $rutaActual -PathType Leaf) { return $coincidencia.Value }
            }
            elseif (-not $uri.StartsWith('package:')) {
                $rutaActual = [System.IO.Path]::GetFullPath((Join-Path $archivo.DirectoryName $uri.Replace('/', '\')))
                if (Test-Path -LiteralPath $rutaActual -PathType Leaf) { return $coincidencia.Value }
            }

            $destinoElegido = $null
            if ($uri -eq 'package:radio_app/app_theme.dart') {
                $destinoElegido = Join-Path $lib 'modules\radio\radio_theme.dart'
            }
            elseif ($uri -eq 'package:radio_app/helpers/constants.dart') {
                $destinoElegido = Join-Path $lib 'modules\radio\radio_constants.dart'
            }
            elseif ($uri -eq 'package:radio_app/helpers/utils.dart') {
                $destinoElegido = Join-Path $lib 'modules\radio\radio_utils.dart'
            }
            else {
                $nombre = ($uri -split '/')[-1]
                $candidatos = @($archivosLib | Where-Object { $_.Name -ceq $nombre })
                if ($candidatos.Count -eq 1) {
                    $destinoElegido = $candidatos[0].FullName
                }
                elseif ($nombre -eq 'home_screen.dart') {
                    # Hay dos home_screen.dart (noticias y radio).
                    if ($archivo.FullName -like '*\modules\radio\*') {
                        $destinoElegido = Join-Path $lib 'modules\radio\screens\home_screen.dart'
                    }
                    else {
                        $destinoElegido = Join-Path $lib 'modules\news\screens\home_screen.dart'
                    }
                }
            }

            if ($null -eq $destinoElegido -or -not (Test-Path -LiteralPath $destinoElegido -PathType Leaf)) {
                $script:pendientes.Add("$($archivo.FullName): $uri")
                return $coincidencia.Value
            }
            $relativaLib = $destinoElegido.Substring($lib.Length).TrimStart('\', '/')
            $nuevaUri = 'package:app_noticias/' + $relativaLib.Replace('\', '/')
            $script:totalCambios++
            return $coincidencia.Groups['antes'].Value + $nuevaUri + $coincidencia.Groups['despues'].Value
        })

    if ($actualizado -cne $contenido) {
        $relativaRaiz = $archivo.FullName.Substring($raiz.Length).TrimStart('\', '/')
        $respaldo = Join-Path $carpetaBackup $relativaRaiz
        $carpetaDestino = Split-Path -Parent $respaldo
        if (-not (Test-Path -LiteralPath $carpetaDestino)) {
            New-Item -ItemType Directory -Path $carpetaDestino -Force | Out-Null
        }
        Copy-Item -LiteralPath $archivo.FullName -Destination $respaldo
        [System.IO.File]::WriteAllText($archivo.FullName, $actualizado, $encodingUtf8)
        $script:totalArchivos++
    }
}

Write-Host ''
Write-Host "Imports corregidos: $script:totalCambios"
Write-Host "Archivos actualizados: $script:totalArchivos"
if ($script:totalArchivos -gt 0) { Write-Host "Respaldo de archivos originales: $carpetaBackup" }
if ($script:pendientes.Count -gt 0) {
    Write-Warning "Imports que requieren revision manual: $($script:pendientes.Count)"
    $script:pendientes | Select-Object -Unique | Select-Object -First 15 | ForEach-Object { Write-Host " - $_" }
}
Write-Host 'Siguiente comando: flutter analyze'
