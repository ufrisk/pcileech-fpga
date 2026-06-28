Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$srcDirs = Get-ChildItem -Path $root -Recurse -Directory -Filter src |
    Where-Object { Test-Path (Join-Path $_.FullName "pcileech_header.svh") }

if (-not $srcDirs) {
    throw "No PCILeech src directories found"
}

$requiredConfigMacros = @(
    "PCILEECH_CFG_SUBSYS_VEND_ID",
    "PCILEECH_CFG_SUBSYS_ID",
    "PCILEECH_CFG_VEND_ID",
    "PCILEECH_CFG_DEV_ID",
    "PCILEECH_CFG_REV_ID",
    "PCILEECH_CFG_DSN",
    "PCILEECH_CFGTLP_ZERO_DATA",
    "PCILEECH_CFGTLP_PCIE_WRITE_ENABLE",
    "PCILEECH_BAR_IMPL_0",
    "PCILEECH_BAR_IMPL_6"
)

$failures = New-Object System.Collections.Generic.List[string]

foreach ($dir in $srcDirs) {
    $rel = Resolve-Path -Relative $dir.FullName

    $header = Get-Content -Raw (Join-Path $dir.FullName "pcileech_header.svh")
    if ($header -notmatch 'pcileech_device_config\.svh') {
        $failures.Add("$rel/pcileech_header.svh does not include pcileech_device_config.svh")
    }

    $deviceConfigPath = Join-Path $dir.FullName "pcileech_device_config.svh"
    if (-not (Test-Path $deviceConfigPath)) {
        $failures.Add("$rel/pcileech_device_config.svh missing")
    } else {
        $deviceConfig = Get-Content -Raw $deviceConfigPath
        foreach ($macro in $requiredConfigMacros) {
            if ($deviceConfig -notmatch [regex]::Escape($macro)) {
                $failures.Add("$rel/pcileech_device_config.svh missing $macro")
            }
        }
    }

    $fifoPath = Join-Path $dir.FullName "pcileech_fifo.sv"
    if (Test-Path $fifoPath) {
        $fifo = Get-Content -Raw $fifoPath
        foreach ($macro in @(
            "PCILEECH_CFG_SUBSYS_VEND_ID",
            "PCILEECH_CFG_SUBSYS_ID",
            "PCILEECH_CFG_VEND_ID",
            "PCILEECH_CFG_DEV_ID",
            "PCILEECH_CFG_REV_ID",
            "PCILEECH_CFGTLP_ZERO_DATA",
            "PCILEECH_CFGTLP_PCIE_WRITE_ENABLE"
        )) {
            if ($fifo -notmatch [regex]::Escape($macro)) {
                $failures.Add("$rel/pcileech_fifo.sv missing $macro")
            }
        }
    }

    $cfgPath = Join-Path $dir.FullName "pcileech_pcie_cfg_a7.sv"
    if (Test-Path $cfgPath) {
        $cfg = Get-Content -Raw $cfgPath
        $cfgMacros = @(
            "PCILEECH_CFG_DSN",
            "PCILEECH_CFGSPACE_STATUS_REGISTER_AUTO_CLEAR",
            "PCILEECH_CFG_PM_FORCE_STATE",
            "PCILEECH_CFG_PM_FORCE_STATE_EN",
            "PCILEECH_CFG_PM_HALT_ASPM_L0S",
            "PCILEECH_CFG_PM_HALT_ASPM_L1"
        )
        if ($cfg -match 'CFGSPACE_COMMAND_REGISTER_AUTO_SET') {
            $cfgMacros += "PCILEECH_CFGSPACE_COMMAND_REGISTER_AUTO_SET"
        }
        foreach ($macro in $cfgMacros) {
            if ($cfg -notmatch [regex]::Escape($macro)) {
                $failures.Add("$rel/pcileech_pcie_cfg_a7.sv missing $macro")
            }
        }
    }

    $barPath = Join-Path $dir.FullName "pcileech_tlps128_bar_controller.sv"
    if (Test-Path $barPath) {
        $bar = Get-Content -Raw $barPath
        foreach ($macro in 0..6 | ForEach-Object { "PCILEECH_BAR_IMPL_$_" }) {
            if ($bar -notmatch [regex]::Escape($macro)) {
                $failures.Add("$rel/pcileech_tlps128_bar_controller.sv missing $macro")
            }
        }
    }

    Get-ChildItem -Path $dir.FullName -Filter "*.sv" | ForEach-Object {
        $lineNo = 0
        foreach ($line in Get-Content $_.FullName) {
            $lineNo++
            $code = ($line -split '//', 2)[0]
            if ($code -cmatch '(?<!`)PCILEECH_') {
                $failures.Add("$rel/$($_.Name):$lineNo has a PCILEECH macro without a SystemVerilog backtick")
            }
        }
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ -ErrorAction Continue }
    throw "$($failures.Count) endpoint hook checks failed"
}

Write-Host "Endpoint hook checks passed for $($srcDirs.Count) board source directories"
