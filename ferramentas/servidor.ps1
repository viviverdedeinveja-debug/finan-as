param([int]$Port=8765,[string]$Root)
$l=New-Object System.Net.HttpListener; $l.Prefixes.Add("http://localhost:$Port/"); $l.Start(); "servindo $Root em http://localhost:$Port/"
$types=@{'.html'='text/html; charset=utf-8';'.json'='application/json; charset=utf-8';'.js'='text/javascript'}
while($l.IsListening){ $c=$l.GetContext(); $p=[Uri]::UnescapeDataString($c.Request.Url.AbsolutePath.TrimStart('/')); if(-not $p){ $p='index.html' }
  $f=Join-Path $Root $p; if(Test-Path $f -PathType Leaf){ $b=[IO.File]::ReadAllBytes($f); $c.Response.ContentType=$types[[IO.Path]::GetExtension($f)]; $c.Response.OutputStream.Write($b,0,$b.Length) } else { $c.Response.StatusCode=404 }
  $c.Response.Close() }