$port = 8080
$base = "https://cd.210k.cc"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

# 获取本机局域网 IP
$localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.PrefixOrigin -eq 'Dhcp' -or $_.PrefixOrigin -eq 'Manual' } | Select-Object -First 1).IPAddress
if (-not $localIP) { $localIP = "127.0.0.1" }

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://+:$port/")
$listener.Start()

Write-Host ""
Write-Host "======================================"
Write-Host "  Kicky Server Started"
Write-Host "  Local:   http://localhost:$port"
Write-Host "  Network: http://${localIP}:$port"
Write-Host "  Press Ctrl+C to stop"
Write-Host "======================================"
Write-Host ""

Start-Process "http://localhost:$port"

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        $path = $request.Url.LocalPath

        if ($path -match "^/api/") {
            $targetUrl = "$base$path"
            if ($request.Url.Query) { $targetUrl += $request.Url.Query }

            try {
                $webRequest = [System.Net.HttpWebRequest]::Create($targetUrl)
                $webRequest.Method = $request.HttpMethod
                $webRequest.ContentType = $request.ContentType
                $webRequest.Timeout = 30000

                $auth = $request.Headers["Authorization"]
                if ($auth) { $webRequest.Headers["Authorization"] = $auth }

                if ($request.HttpMethod -eq "POST" -and $request.HasEntityBody) {
                    $reader = New-Object System.IO.StreamReader($request.InputStream)
                    $body = $reader.ReadToEnd()
                    $reader.Close()
                    $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
                    $webRequest.ContentLength = $bytes.Length
                    $reqStream = $webRequest.GetRequestStream()
                    $reqStream.Write($bytes, 0, $bytes.Length)
                    $reqStream.Close()
                }

                $webResponse = $webRequest.GetResponse()
                $respStream = $webResponse.GetResponseStream()
                $respReader = New-Object System.IO.StreamReader($respStream)
                $respBody = $respReader.ReadToEnd()
                $respReader.Close()
                $webResponse.Close()

                $response.ContentType = "application/json; charset=utf-8"
                $response.StatusCode = 200
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($respBody)
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)

                Write-Host "[OK] $($request.HttpMethod) $path"
            }
            catch [System.Net.WebException] {
                $errResponse = $_.Exception.Response
                if ($errResponse) {
                    $errStream = $errResponse.GetResponseStream()
                    $errReader = New-Object System.IO.StreamReader($errStream)
                    $errBody = $errReader.ReadToEnd()
                    $errReader.Close()
                    $response.StatusCode = [int]$errResponse.StatusCode
                    $response.ContentType = "application/json; charset=utf-8"
                    $buffer = [System.Text.Encoding]::UTF8.GetBytes($errBody)
                    $response.ContentLength64 = $buffer.Length
                    $response.OutputStream.Write($buffer, 0, $buffer.Length)
                    Write-Host "[ERR] $($request.HttpMethod) $path -> $([int]$errResponse.StatusCode)"
                } else {
                    $response.StatusCode = 502
                    $errMsg = '{"error":"API connection failed"}'
                    $buffer = [System.Text.Encoding]::UTF8.GetBytes($errMsg)
                    $response.ContentLength64 = $buffer.Length
                    $response.OutputStream.Write($buffer, 0, $buffer.Length)
                    Write-Host "[ERR] $($request.HttpMethod) $path -> 502"
                }
            }
        }
        else {
            $filePath = if ($path -eq "/") { Join-Path $root "index.html" } else { Join-Path $root $path.TrimStart("/") }

            if (Test-Path $filePath) {
                $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
                $mimeTypes = @{
                    ".html" = "text/html; charset=utf-8"
                    ".css"  = "text/css; charset=utf-8"
                    ".js"   = "application/javascript; charset=utf-8"
                    ".json" = "application/json; charset=utf-8"
                    ".png"  = "image/png"
                    ".jpg"  = "image/jpeg"
                    ".ico"  = "image/x-icon"
                }
                $response.ContentType = if ($mimeTypes[$ext]) { $mimeTypes[$ext] } else { "application/octet-stream" }
                $buffer = [System.IO.File]::ReadAllBytes($filePath)
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            }
            else {
                $response.StatusCode = 404
                $buffer = [System.Text.Encoding]::UTF8.GetBytes("Not Found")
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            }
        }

        $response.OutputStream.Close()
    }
    catch {
        Write-Host "Error: $_"
    }
}
