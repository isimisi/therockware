<#
  Authenticode-sign the exe.

    .\sign.ps1 -PfxPath mycert.pfx -PfxPassword hunter2   # a real CA cert
    .\sign.ps1 -SelfSigned                                # your own machines

  Honest note on "trusted": only a code-signing certificate from a public CA
  buys SmartScreen trust, and only an EV cert gets it immediately -- an OV cert
  still has to build download reputation first. -SelfSigned makes the exe
  properly signed and trusted on machines where the cert is installed (this
  one, automatically), which is what you want for personal use; it does nothing
  for a stranger downloading it.
#>
[CmdletBinding()]
param(
  [string] $Exe          = "build\therockware.exe",
  [string] $PfxPath,
  [string] $PfxPassword,
  [switch] $SelfSigned,
  [string] $TimestampUrl = "http://timestamp.digicert.com"
)

$ErrorActionPreference = "Stop"
if (-not (Test-Path $Exe)) { throw "No exe at $Exe -- run build.bat first." }

$signtool = Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits\10\bin\*\x64\signtool.exe" `
              -ErrorAction SilentlyContinue | Sort-Object FullName | Select-Object -Last 1
if (-not $signtool) { throw "signtool.exe not found -- install the Windows 10/11 SDK." }

if ($SelfSigned) {
  $subject = "CN=TheRockWare"
  $cert = Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.Subject -eq $subject } |
          Select-Object -First 1
  if (-not $cert) {
    Write-Host "Creating a self-signed code-signing certificate..."
    $cert = New-SelfSignedCertificate -Type CodeSigningCert -Subject $subject `
              -CertStoreLocation Cert:\CurrentUser\My -NotAfter (Get-Date).AddYears(5)
  }
  # Trust it on this machine: root of the chain + allowed publisher.
  foreach ($store in @("Root", "TrustedPublisher")) {
    $s = New-Object System.Security.Cryptography.X509Certificates.X509Store($store, "CurrentUser")
    $s.Open("ReadWrite"); $s.Add($cert); $s.Close()
  }
  & $signtool.FullName sign /fd SHA256 /td SHA256 /tr $TimestampUrl `
      /sha1 $cert.Thumbprint $Exe
}
elseif ($PfxPath) {
  if (-not (Test-Path $PfxPath)) { throw "No pfx at $PfxPath" }
  $args = @("sign", "/fd", "SHA256", "/td", "SHA256", "/tr", $TimestampUrl, "/f", $PfxPath)
  if ($PfxPassword) { $args += @("/p", $PfxPassword) }
  & $signtool.FullName @args $Exe
}
else {
  throw "Pass -SelfSigned or -PfxPath <file>."
}

if ($LASTEXITCODE -ne 0) { throw "signtool failed ($LASTEXITCODE)" }
& $signtool.FullName verify /pa /v $Exe
