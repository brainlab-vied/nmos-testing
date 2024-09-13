# Windows script to start nmos-testing tool

param(
    [switch]$e,  # Default is $false
    [switch]$u,  # Default is $false
    [string]$c
)

# Exit on error
$ErrorActionPreference = "Stop"

$mainRepoRoot = git rev-parse --show-toplevel

if (-not $c) {
    $c = "$mainRepoRoot/../BuzzVirtual-Gen2-documentation/certificates/"
}

# Usage / Help
if ($args -contains '-help' -or $args -contains '--help') {
    Write-Host "Usage: ./setup.ps1 [-e] [-c <certificate_path>]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -e              Enable HTTPS (default: false)"
    Write-Host "  -u  Enable unicast DNS-SD discovery (default: false)"
    Write-Host "  -c <string>     Path to certificate (default: '../../../BuzzVirtual-Gen2-documentation/certificates/')"
    exit
}

$dns_mode = "multicast"
if($u) {
    $dns_mode = "unicast"
}

# Create UserConfig.py
$configContent = @"
# # Copyright (C) 2020 Advanced Media Workflow Association
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from . import Config as CONFIG

# Copy this file to "UserConfig.py" to change configuration values.

CONFIG.CERT_CLIENT = ("$c/mgmt-client-combined.pem.crt", "$c/mgmt-client.pem.key")
CONFIG.CERT_TRUST_ROOT_CA = False
CONFIG.ENABLE_HTTPS = $e
CONFIG.DNS_SD_MODE = "$dns_mode"
"@

Write-Output "Creating UserConfig.py"
Set-Content -Path $mainRepoRoot/amwa/nmos-testing/nmostesting/UserConfig.py -Value $configContent

# Run the scripts
Write-Output "Starting nmos-testing"
$testProcess = Start-Process py -ArgumentList "$mainRepoRoot/amwa/nmos-testing/nmos-test.py" -NoNewWindow -PassThru

Write-Output "Starting facade"
$facadeProcess = Start-Process py -ArgumentList "$mainRepoRoot/amwa/nmos-testing/nmos-testing-facade.py" -NoNewWindow -PassThru

# Wait for processes to finish
$testProcess.WaitForExit()
$facadeProcess.WaitForExit()
