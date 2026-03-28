$env:OLLAMA_MODELS = "E:\1C_Infrastructure\AI\Ollama\models"
$env:OLLAMA_HOST = "0.0.0.0:11434"
$logFile = "E:\1C_Infrastructure\AI\Ollama\logs\ollama-(Get-Date -Format 'yyyyMMdd').log"

Start-Transcript -Path $logFile -Append
Write-Host "Starting Ollama from: E:\1C_Infrastructure\AI\Ollama\bin"
& "E:\1C_Infrastructure\AI\Ollama\bin\ollama.exe" serve
