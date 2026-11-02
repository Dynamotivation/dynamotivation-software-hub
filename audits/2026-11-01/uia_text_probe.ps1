# Diagnostic: probe UI Automation text patterns of the running Hub window.
# Limitation: on 2026-11-02 this returned only the outer FLUTTERVIEW pane.
# No child Text/Value pattern results were obtained; absence here is not proof
# that a Flutter control does not expose those patterns. Prefer the supported
# desktop helper and Narrator speech recap for native acceptance evidence.
# Usage: powershell -NoProfile -File uia_text_probe.ps1 -Exe <path to dynamotivation_software_hub.exe>
param([Parameter(Mandatory)][string]$Exe)
Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes
$p = Start-Process -FilePath $Exe -PassThru
try {
  $root = $null
  for ($i = 0; $i -lt 40 -and -not $root; $i++) {
    Start-Sleep -Milliseconds 500
    $root = [Windows.Automation.AutomationElement]::RootElement.FindFirst(
      'Children', (New-Object Windows.Automation.PropertyCondition(
        [Windows.Automation.AutomationElement]::ProcessIdProperty, $p.Id)))
  }
  if (-not $root) { throw 'window not found' }
  # Flutter builds its semantics tree only after a client first queries it.
  for ($i = 0; $i -lt 6; $i++) {
    Start-Sleep -Seconds 1
    $n = $root.FindAll('Descendants', [Windows.Automation.Condition]::TrueCondition).Count
    if ($n -gt 1) { break }
  }
  foreach ($x in $root.FindAll('Descendants', [Windows.Automation.Condition]::TrueCondition)) {
    "tree: $($x.Current.ControlType.ProgrammaticName) '$($x.Current.Name)' class='$($x.Current.ClassName)'"
  }
  $edits = $root.FindAll('Descendants', (New-Object Windows.Automation.PropertyCondition(
    [Windows.Automation.AutomationElement]::ControlTypeProperty,
    [Windows.Automation.ControlType]::Edit)))
  "edits found: $($edits.Count)"
  foreach ($e in $edits) {
    "--- Name='$($e.Current.Name)' Class='$($e.Current.ClassName)' HasFocus=$($e.Current.HasKeyboardFocus)"
    foreach ($pat in $e.GetSupportedPatterns()) { "  pattern: $($pat.ProgrammaticName)" }
    try { $e.SetFocus() } catch { "  SetFocus failed: $_" }
    Start-Sleep -Milliseconds 400
    $tp = $null
    if ($e.TryGetCurrentPattern([Windows.Automation.TextPattern]::Pattern, [ref]$tp)) {
      "  doc range text: '$($tp.DocumentRange.GetText(-1))'"
      "  selection ranges: $($tp.GetSelection().Count)"
      "  visible ranges: $($tp.GetVisibleRanges().Count)"
    } else { '  no TextPattern' }
    $vp = $null
    if ($e.TryGetCurrentPattern([Windows.Automation.ValuePattern]::Pattern, [ref]$vp)) {
      "  value: '$($vp.Current.Value)' readonly=$($vp.Current.IsReadOnly)"
    }
  }
} finally { Stop-Process -Id $p.Id -ErrorAction SilentlyContinue }
