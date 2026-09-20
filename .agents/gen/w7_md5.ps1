$path = 'res://assets/ships/ship_interceptor_side.png'
$md5 = [System.Security.Cryptography.MD5]::Create()
$bytes = [System.Text.Encoding]::UTF8.GetBytes($path)
$hash = ($md5.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join ''
Write-Output "md5(path text) = $hash"
