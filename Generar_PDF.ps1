# Script para generar PDF desde HTML
$htmlFile = "Manual_Copiar_Empresa.html"
$pdfFile = "Manual_Copiar_Empresa.pdf"

# Verificar que existe el archivo HTML
if (-not (Test-Path $htmlFile)) {
    Write-Host "Error: No se encontró el archivo $htmlFile"
    exit 1
}

# Intentar con Chrome
$chromePaths = @(
    "C:\Program Files\Google\Chrome\Application\chrome.exe",
    "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
)

foreach ($chromePath in $chromePaths) {
    if (Test-Path $chromePath) {
        Write-Host "Generando PDF con Chrome..."
        $htmlFullPath = Resolve-Path $htmlFile
        $pdfFullPath = Join-Path (Get-Location) $pdfFile
        
        & $chromePath --headless --disable-gpu --print-to-pdf=$pdfFullPath --print-to-pdf-no-header $htmlFullPath
        
        if (Test-Path $pdfFile) {
            Write-Host "PDF generado exitosamente: $pdfFile"
            exit 0
        }
    }
}

# Intentar con Edge
$edgePaths = @(
    "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
)

foreach ($edgePath in $edgePaths) {
    if (Test-Path $edgePath) {
        Write-Host "Generando PDF con Edge..."
        $htmlFullPath = Resolve-Path $htmlFile
        $pdfFullPath = Join-Path (Get-Location) $pdfFile
        
        & $edgePath --headless --disable-gpu --print-to-pdf=$pdfFullPath --print-to-pdf-no-header $htmlFullPath
        
        if (Test-Path $pdfFile) {
            Write-Host "PDF generado exitosamente: $pdfFile"
            exit 0
        }
    }
}

Write-Host ""
Write-Host "No se pudo generar el PDF automáticamente."
Write-Host "Por favor, siga estos pasos:"
Write-Host "1. Abra el archivo '$htmlFile' en su navegador"
Write-Host "2. Presione Ctrl+P (o Cmd+P en Mac)"
Write-Host "3. Seleccione 'Guardar como PDF' como destino"
Write-Host "4. Guarde el archivo como '$pdfFile'"

