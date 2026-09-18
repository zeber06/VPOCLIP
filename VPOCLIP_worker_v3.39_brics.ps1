param(
    [Parameter(Mandatory = $true)][string]$BricsExe,
    [string]$BricsProfile = '',
    [Parameter(Mandatory = $true)][string]$SourceDwg,
    [Parameter(Mandatory = $true)][string]$Manifest,
    [Parameter(Mandatory = $true)][string]$Report,
    [Parameter(Mandatory = $true)][string]$WorkerScript,
    [Parameter(Mandatory = $true)][string]$Progress,
    [Parameter(Mandatory = $true)][string]$Done,
    [Parameter(Mandatory = $true)][string]$Results,
    [Parameter(Mandatory = $true)][int]$Overwrite,
    [int]$ShowProgress = 1,
    [int]$PanelDiagnostic = 0,
    [int]$CompletionSeconds = 0,
    [int]$IdleTimeoutSeconds = 600,
    [ValidateSet(-1, 0, 1)][int]$ProcessAllLayouts = -1
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
try {
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class VpoClipConsole {
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc callback, IntPtr lParam);
    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);

    public static void HideProcessWindows(int processId) {
        EnumWindows(delegate(IntPtr hWnd, IntPtr lParam) {
            uint ownerProcessId;
            GetWindowThreadProcessId(hWnd, out ownerProcessId);
            if (ownerProcessId == (uint)processId) {
                ShowWindow(hWnd, 0);
            }
            return true;
        }, IntPtr.Zero);
    }
}
'@
$consoleHandle = [VpoClipConsole]::GetConsoleWindow()
if ($consoleHandle -ne [IntPtr]::Zero) {
    $null = [VpoClipConsole]::ShowWindow($consoleHandle, 0)
}
}
catch { }
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$controlEncoding = [System.Text.Encoding]::GetEncoding(1250)
$script:panelEnabled = $false
$script:batchComplete = $false
$script:progressForm = $null
$script:progressBar = $null
$script:summaryLabel = $null
$script:optionsLabel = $null
$script:protectedLayersLabel = $null
$script:currentLabel = $null
$script:detailLabel = $null
$script:taskList = $null
$script:exportDirectory = ''
$script:exportPathTextBox = $null
$script:openExportFolderButton = $null
$script:cancelButton = $null
$script:closeButton = $null
$script:progressItems = @()
$script:panelTasks = @()
$script:batchEndWritten = $false
$script:cancelRequested = $false

function Add-ReportLine {
    param([string]$Line)
    [System.IO.File]::AppendAllText(
        $Report,
        $Line + [Environment]::NewLine,
        $utf8NoBom)
}

function Add-BatchEnd {
    if (-not $script:batchEndWritten) {
        Add-ReportLine 'BATCH_END'
        $script:batchEndWritten = $true
    }
}

function Remove-FileConfirmed {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path) -or -not [System.IO.File]::Exists($Path)) {
        return
    }
    [System.IO.File]::Delete($Path)
    if ([System.IO.File]::Exists($Path)) {
        throw "Nie mozna usunac pliku: $Path"
    }
}

function Test-DwgFile {
    param([string]$Path)
    if (-not [System.IO.File]::Exists($Path)) { return $false }
    $stream = [System.IO.File]::OpenRead($Path)
    try {
        $buffer = [byte[]]::new(4)
        if ($stream.Read($buffer, 0, 4) -ne 4) { return $false }
        return [System.Text.Encoding]::ASCII.GetString($buffer) -eq 'AC10'
    }
    finally {
        $stream.Dispose()
    }
}

function Test-PdfFile {
    param([string]$Path)
    if (-not [System.IO.File]::Exists($Path)) { return $false }
    $stream = [System.IO.File]::OpenRead($Path)
    try {
        $buffer = [byte[]]::new(5)
        if ($stream.Read($buffer, 0, 5) -ne 5) { return $false }
        return [System.Text.Encoding]::ASCII.GetString($buffer) -eq '%PDF-'
    }
    finally {
        $stream.Dispose()
    }
}

function Pump-ProgressPanel {
    if ($script:panelEnabled -and $null -ne $script:progressForm -and
        -not $script:progressForm.IsDisposed) {
        [System.Windows.Forms.Application]::DoEvents()
    }
}

function Wait-ProcessExit {
    param(
        [System.Diagnostics.Process]$Process,
        [int]$Milliseconds
    )
    $deadline = [DateTime]::UtcNow.AddMilliseconds($Milliseconds)
    while ([DateTime]::UtcNow -lt $deadline) {
        $Process.Refresh()
        if ($Process.HasExited) { return $true }
        Pump-ProgressPanel
        if ($script:cancelRequested) { return $false }
        Start-Sleep -Milliseconds 200
    }
    return $false
}

function Hide-WorkerMainWindow {
    param(
        [System.Diagnostics.Process]$Process,
        [int]$Milliseconds = 0
    )
    $deadline = [DateTime]::UtcNow.AddMilliseconds([Math]::Max(0, $Milliseconds))
    do {
        try {
            $Process.Refresh()
            if ($Process.HasExited) { return $false }
            [VpoClipConsole]::HideProcessWindows($Process.Id)
            if ($Process.MainWindowHandle -ne [IntPtr]::Zero) {
                return $true
            }
        }
        catch {
            return $false
        }
        if ([DateTime]::UtcNow -ge $deadline) { return $false }
        Pump-ProgressPanel
        if ($script:cancelRequested) { return $false }
        Start-Sleep -Milliseconds 200
    } while ($true)
}

function Stop-WorkerProcess {
    param(
        [System.Diagnostics.Process]$Process,
        [switch]$Immediate
    )
    if ($null -eq $Process) { return }
    try {
        $Process.Refresh()
        if ($Process.HasExited) { return }
        if ($Immediate) {
            Stop-Process -Id $Process.Id -Force -ErrorAction SilentlyContinue
            $null = Wait-ProcessExit -Process $Process -Milliseconds 10000
            return
        }
        if (Wait-ProcessExit -Process $Process -Milliseconds 45000) { return }
        $null = $Process.CloseMainWindow()
        if (Wait-ProcessExit -Process $Process -Milliseconds 30000) { return }
        Stop-Process -Id $Process.Id -Force -ErrorAction SilentlyContinue
        $null = Wait-ProcessExit -Process $Process -Milliseconds 10000
    }
    catch { }
}

function Remove-LegacyWorkFiles {
    param([string]$FinalDwg)
    $dir = [System.IO.Path]::GetDirectoryName($FinalDwg)
    $base = [System.IO.Path]::GetFileNameWithoutExtension($FinalDwg)
    if ([string]::IsNullOrWhiteSpace($dir) -or [string]::IsNullOrWhiteSpace($base)) {
        return
    }
    Get-ChildItem -LiteralPath $dir -File -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -like ($base + '._VPOCLIP_WORK_*') -and
            $_.Extension -in '.dwg', '.pdf', '.bak', '.status'
        } |
        ForEach-Object {
            try { Remove-FileConfirmed -Path $_.FullName } catch { }
        }
}

function Get-ExportDirectory {
    param([object[]]$Tasks)
    foreach ($task in $Tasks) {
        $candidate = if ($task.CreateDwg) { $task.FinalDwg } else { $task.FinalPdf }
        if (-not [string]::IsNullOrWhiteSpace($candidate)) {
            $directory = [System.IO.Path]::GetDirectoryName($candidate)
            if (-not [string]::IsNullOrWhiteSpace($directory)) {
                return [System.IO.Path]::GetFullPath($directory)
            }
        }
    }
    return ''
}

function Open-ExportDirectory {
    if ([string]::IsNullOrWhiteSpace($script:exportDirectory)) { return }
    try {
        if (-not [System.IO.Directory]::Exists($script:exportDirectory)) {
            [System.IO.Directory]::CreateDirectory($script:exportDirectory) | Out-Null
        }
        $safePath = $script:exportDirectory.Replace('"', '')
        $null = [System.Diagnostics.Process]::Start(
            'explorer.exe', '/e,"' + $safePath + '"')
    }
    catch {
        if ($null -ne $script:detailLabel) {
            $script:detailLabel.Text = "Nie mozna otworzyc folderu eksportu: $($_.Exception.Message)"
        }
    }
}

function Get-PanelOptionSummary {
    param([object[]]$Tasks)
    $createDwg = @($Tasks | Where-Object { $_.CreateDwg }).Count -gt 0
    $createPdf = @($Tasks | Where-Object { $_.CreatePdf }).Count -gt 0
    $pdfModes = @($Tasks | Where-Object { $_.CreatePdf } |
        Select-Object -ExpandProperty PdfFromSource -Unique)
    $xrefModes = @($Tasks | Select-Object -ExpandProperty IgnoreXref -Unique)
    $frameModes = @($Tasks | Select-Object -ExpandProperty AutoCreateFrames -Unique)

    $dwgText = if ($createDwg) { 'TAK' } else { 'NIE' }
    $pdfText = if (-not $createPdf) {
        'NIE'
    }
    elseif ($pdfModes.Count -eq 1 -and $pdfModes[0]) {
        'TAK, ze zrodla'
    }
    elseif ($pdfModes.Count -eq 1) {
        'TAK, po podziale'
    }
    else {
        'TAK, tryb mieszany'
    }
    $xrefText = if ($xrefModes.Count -eq 1 -and $xrefModes[0]) {
        'wszystkie'
    }
    elseif ($xrefModes.Count -eq 1) {
        'wg klucza'
    }
    else {
        'tryb mieszany'
    }
    $frameText = if ($frameModes.Count -eq 1 -and $frameModes[0]) {
        'automatyczne'
    }
    elseif ($frameModes.Count -eq 1) {
        'tylko VPOutline'
    }
    else {
        'tryb mieszany'
    }
    $layoutText = switch ($ProcessAllLayouts) {
        1 { 'wszystkie' }
        0 { 'sekcja TASKS' }
        default { 'wybrane przez LCLIP' }
    }
    return "DWG: $dwgText   |   PDF: $pdfText   |   XREF: $xrefText   |   Ramki: $frameText   |   Layouty: $layoutText"
}

function Get-ProtectedLayersSummary {
    param([object[]]$Tasks)
    $patterns = @($Tasks | ForEach-Object { $_.IgnoreLayers } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Select-Object -Unique)
    if ($patterns.Count -eq 0) {
        return 'Chronione warstwy: brak'
    }
    return 'Chronione warstwy: ' + ($patterns -join '; ')
}

function Request-Cancellation {
    if ($script:batchComplete -or $script:cancelRequested) { return }
    $answer = [System.Windows.Forms.MessageBox]::Show(
        $script:progressForm,
        "Przerwac eksport?`n`nUkonczone zadania zostana zachowane, a niedokonczone wyniki odrzucone.",
        'VPOCLIP - przerwanie eksportu',
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning,
        [System.Windows.Forms.MessageBoxDefaultButton]::Button2)
    if ($answer -eq [System.Windows.Forms.DialogResult]::Yes) {
        $script:cancelRequested = $true
        $script:cancelButton.Enabled = $false
        $script:currentLabel.Text = 'Przerywanie eksportu'
        $script:currentLabel.ForeColor = [System.Drawing.Color]::Firebrick
        $script:detailLabel.Text =
            'Zatrzymywanie roboczej instancji BricsCAD i odrzucanie niedokonczonych wynikow.'
    }
}
function Initialize-ProgressPanel {
    param([object[]]$Tasks)
    if ($ShowProgress -ne 1) { return }

    try {
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class VpoClipNativeWindow {
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(
        IntPtr hWnd, IntPtr insertAfter, int x, int y, int cx, int cy, uint flags);
}
"@
        [System.Windows.Forms.Application]::EnableVisualStyles()

        $script:panelTasks = @($Tasks)
        $script:exportDirectory = Get-ExportDirectory -Tasks $Tasks
        $script:progressForm = [System.Windows.Forms.Form]::new()
        $script:progressForm.Text = 'VPOCLIP 3.37 BricsCAD - postep eksportu'
        $script:progressForm.StartPosition = 'CenterScreen'
        $script:progressForm.ClientSize = [System.Drawing.Size]::new(760, 575)
        $script:progressForm.MinimumSize = [System.Drawing.Size]::new(700, 610)
        $script:progressForm.BackColor = [System.Drawing.Color]::White
        $script:progressForm.Font = [System.Drawing.Font]::new('Segoe UI', 9)
        $script:progressForm.ShowInTaskbar = $true
        $script:progressForm.TopMost = $true
        $script:progressForm.MaximizeBox = $false

        $titleLabel = [System.Windows.Forms.Label]::new()
        $titleLabel.Text = 'Eksport layoutow do DWG i PDF'
        $titleLabel.Location = [System.Drawing.Point]::new(20, 16)
        $titleLabel.Size = [System.Drawing.Size]::new(710, 30)
        $titleLabel.Font = [System.Drawing.Font]::new('Segoe UI Semibold', 14)
        $titleLabel.Anchor = 'Top, Left, Right'

        $script:summaryLabel = [System.Windows.Forms.Label]::new()
        $script:summaryLabel.Text = "Do wykonania: $($Tasks.Count)"
        $script:summaryLabel.Location = [System.Drawing.Point]::new(20, 53)
        $script:summaryLabel.Size = [System.Drawing.Size]::new(710, 22)
        $script:summaryLabel.Anchor = 'Top, Left, Right'

        $script:optionsLabel = [System.Windows.Forms.Label]::new()
        $script:optionsLabel.Text = Get-PanelOptionSummary -Tasks $Tasks
        $script:optionsLabel.Location = [System.Drawing.Point]::new(20, 80)
        $script:optionsLabel.Size = [System.Drawing.Size]::new(720, 22)
        $script:optionsLabel.Font = [System.Drawing.Font]::new('Segoe UI Semibold', 9)
        $script:optionsLabel.AutoEllipsis = $true
        $script:optionsLabel.Anchor = 'Top, Left, Right'

        $script:protectedLayersLabel = [System.Windows.Forms.Label]::new()
        $script:protectedLayersLabel.Text = Get-ProtectedLayersSummary -Tasks $Tasks
        $script:protectedLayersLabel.Location = [System.Drawing.Point]::new(20, 104)
        $script:protectedLayersLabel.Size = [System.Drawing.Size]::new(720, 22)
        $script:protectedLayersLabel.AutoEllipsis = $true
        $script:protectedLayersLabel.Anchor = 'Top, Left, Right'

        $script:currentLabel = [System.Windows.Forms.Label]::new()
        $script:currentLabel.Text = 'Przygotowanie listy zadan'
        $script:currentLabel.Location = [System.Drawing.Point]::new(20, 137)
        $script:currentLabel.Size = [System.Drawing.Size]::new(710, 22)
        $script:currentLabel.Font = [System.Drawing.Font]::new('Segoe UI Semibold', 9)
        $script:currentLabel.Anchor = 'Top, Left, Right'

        $script:progressBar = [System.Windows.Forms.ProgressBar]::new()
        $script:progressBar.Location = [System.Drawing.Point]::new(20, 165)
        $script:progressBar.Size = [System.Drawing.Size]::new(720, 20)
        $script:progressBar.Minimum = 0
        $script:progressBar.Maximum = [Math]::Max(1, $Tasks.Count * 100)
        $script:progressBar.Value = 0
        $script:progressBar.Style = 'Continuous'
        $script:progressBar.Anchor = 'Top, Left, Right'

        $listLabel = [System.Windows.Forms.Label]::new()
        $listLabel.Text = 'Zadania do wykonania'
        $listLabel.Location = [System.Drawing.Point]::new(20, 196)
        $listLabel.Size = [System.Drawing.Size]::new(300, 20)
        $listLabel.Font = [System.Drawing.Font]::new('Segoe UI Semibold', 9)

        $script:taskList = [System.Windows.Forms.ListView]::new()
        $script:taskList.Location = [System.Drawing.Point]::new(20, 219)
        $script:taskList.Size = [System.Drawing.Size]::new(720, 220)
        $script:taskList.View = 'Details'
        $script:taskList.FullRowSelect = $true
        $script:taskList.GridLines = $true
        $script:taskList.HideSelection = $false
        $script:taskList.MultiSelect = $false
        $script:taskList.Anchor = 'Top, Bottom, Left, Right'
        $null = $script:taskList.Columns.Add('Nr', 42)
        $null = $script:taskList.Columns.Add('Layout', 95)
        $null = $script:taskList.Columns.Add('Plik wynikowy', 400)
        $null = $script:taskList.Columns.Add('Status', 155)

        $script:progressItems = @()
        for ($i = 0; $i -lt $Tasks.Count; $i++) {
            $task = $Tasks[$i]
            $item = [System.Windows.Forms.ListViewItem]::new(($i + 1).ToString())
            $null = $item.SubItems.Add($task.Layout)
            $displayPath = if ($task.CreateDwg) { $task.FinalDwg } else { $task.FinalPdf }
            $null = $item.SubItems.Add([System.IO.Path]::GetFileName($displayPath))
            $null = $item.SubItems.Add('Oczekuje')
            $item.UseItemStyleForSubItems = $false
            $null = $script:taskList.Items.Add($item)
            $script:progressItems += $item
        }

        $exportPathLabel = [System.Windows.Forms.Label]::new()
        $exportPathLabel.Text = 'Folder eksportu'
        $exportPathLabel.Location = [System.Drawing.Point]::new(20, 449)
        $exportPathLabel.Size = [System.Drawing.Size]::new(300, 20)
        $exportPathLabel.Font = [System.Drawing.Font]::new('Segoe UI Semibold', 9)
        $exportPathLabel.Anchor = 'Bottom, Left'

        $script:exportPathTextBox = [System.Windows.Forms.TextBox]::new()
        $script:exportPathTextBox.Text = $script:exportDirectory
        $script:exportPathTextBox.Location = [System.Drawing.Point]::new(20, 471)
        $script:exportPathTextBox.Size = [System.Drawing.Size]::new(550, 24)
        $script:exportPathTextBox.ReadOnly = $true
        $script:exportPathTextBox.BackColor = [System.Drawing.Color]::White
        $script:exportPathTextBox.Anchor = 'Bottom, Left, Right'

        $script:openExportFolderButton = [System.Windows.Forms.Button]::new()
        $script:openExportFolderButton.Text = 'Otworz folder'
        $script:openExportFolderButton.Location = [System.Drawing.Point]::new(585, 469)
        $script:openExportFolderButton.Size = [System.Drawing.Size]::new(155, 28)
        $script:openExportFolderButton.Enabled =
            -not [string]::IsNullOrWhiteSpace($script:exportDirectory)
        $script:openExportFolderButton.Anchor = 'Bottom, Right'
        $script:openExportFolderButton.Add_Click({ Open-ExportDirectory })

        $script:detailLabel = [System.Windows.Forms.Label]::new()
        $script:detailLabel.Text = 'Oczekiwanie na rozpoczecie eksportu'
        $script:detailLabel.Location = [System.Drawing.Point]::new(20, 513)
        $script:detailLabel.Size = [System.Drawing.Size]::new(500, 42)
        $script:detailLabel.AutoEllipsis = $true
        $script:detailLabel.Anchor = 'Bottom, Left, Right'

        $script:cancelButton = [System.Windows.Forms.Button]::new()
        $script:cancelButton.Text = 'Przerwij'
        $script:cancelButton.Location = [System.Drawing.Point]::new(540, 516)
        $script:cancelButton.Size = [System.Drawing.Size]::new(95, 30)
        $script:cancelButton.Enabled = $true
        $script:cancelButton.Anchor = 'Bottom, Right'
        $script:cancelButton.Add_Click({ Request-Cancellation })

        $script:closeButton = [System.Windows.Forms.Button]::new()
        $script:closeButton.Text = 'Zamknij'
        $script:closeButton.Location = [System.Drawing.Point]::new(645, 516)
        $script:closeButton.Size = [System.Drawing.Size]::new(95, 30)
        $script:closeButton.Enabled = $false
        $script:closeButton.Anchor = 'Bottom, Right'
        $script:closeButton.Add_Click({ $script:progressForm.Close() })

        $script:progressForm.Add_FormClosing({
            param($sender, $eventArgs)
            if (-not $script:batchComplete) {
                $eventArgs.Cancel = $true
                Request-Cancellation
            }
        })

        $script:progressForm.Controls.AddRange(@(
            $titleLabel,
            $script:summaryLabel,
            $script:optionsLabel,
            $script:protectedLayersLabel,
            $script:currentLabel,
            $script:progressBar,
            $listLabel,
            $script:taskList,
            $exportPathLabel,
            $script:exportPathTextBox,
            $script:openExportFolderButton,
            $script:detailLabel,
            $script:cancelButton,
            $script:closeButton))

        $script:panelEnabled = $true
        $script:progressForm.Show()
        $null = [VpoClipNativeWindow]::ShowWindow($script:progressForm.Handle, 0)
        $null = [VpoClipNativeWindow]::ShowWindow($script:progressForm.Handle, 5)
        $null = [VpoClipNativeWindow]::SetWindowPos(
            $script:progressForm.Handle, [IntPtr](-1), 0, 0, 0, 0, 0x0043)
        $null = [VpoClipNativeWindow]::SetForegroundWindow($script:progressForm.Handle)
        $script:progressForm.Activate()
        Pump-ProgressPanel
        if ($PanelDiagnostic -eq 1) {
            $nativeVisible = [VpoClipNativeWindow]::IsWindowVisible(
                $script:progressForm.Handle)
            Add-ReportLine (
                "PANEL|READY|form=$($script:progressForm.Visible)|" +
                "window=$nativeVisible|handle=$($script:progressForm.Handle)|" +
                "export=$script:exportDirectory|" +
                "options=$($script:optionsLabel.Text)|" +
                "cancelButton=$($script:cancelButton.Enabled)")
        }
    }
    catch {
        $script:panelEnabled = $false
        try { Add-ReportLine "WARN|PANEL||$($_.Exception.Message)" } catch { }
    }
}
function Get-StagePercent {
    param([string]$Code)
    switch ($Code) {
        'OPEN'      { return 5 }
        'PRECHECK'  { return 12 }
        'XREF'      { return 25 }
        'PDF'       { return 40 }
        'FRAME'     { return 45 }
        'MODEL'     { return 50 }
        'PURGE'     { return 65 }
        'VERIFY'    { return 75 }
        'SAVE'      { return 82 }
        'WBLOCK'    { return 86 }
        'UNDO'      { return 95 }
        'TASK_OK'   { return 100 }
        'TASK_FAIL' { return 100 }
        'FINAL'     { return 100 }
        default     { return 3 }
    }
}

function Update-ProgressPanel {
    param(
        [int]$Index,
        [string]$Status,
        [string]$Stage,
        [int]$Processed,
        [int]$Failed,
        [string]$Detail,
        [string]$Kind = 'Active',
        [string]$Code = ''
    )
    if (-not $script:panelEnabled -or $script:progressForm.IsDisposed) { return }

    try {
        $total = $script:panelTasks.Count
        $remaining = [Math]::Max(0, $total - $Processed)
        $script:summaryLabel.Text =
            "Wykonano: $Processed z $total    Bledy: $Failed    Pozostalo: $remaining"
        $script:currentLabel.Text = $Stage
        $script:detailLabel.Text = $Detail

        $progressTarget = [Math]::Max(0, $Processed * 100)
        if ($Index -ge 0 -and -not [string]::IsNullOrWhiteSpace($Code)) {
            $progressTarget = ($Index * 100) + (Get-StagePercent -Code $Code)
            if ($Code -in @('TASK_OK', 'TASK_FAIL')) {
                $progressTarget = ($Index + 1) * 100
            }
        }
        $progressTarget = [Math]::Min($script:progressBar.Maximum, $progressTarget)
        $script:progressBar.Value = [Math]::Max(
            $script:progressBar.Value, $progressTarget)

        if ($Index -ge 0 -and $Index -lt $script:progressItems.Count) {
            $item = $script:progressItems[$Index]
            $item.SubItems[3].Text = $Status
            switch ($Kind) {
                'Success' { $item.SubItems[3].ForeColor = [System.Drawing.Color]::ForestGreen }
                'Error'   { $item.SubItems[3].ForeColor = [System.Drawing.Color]::Firebrick }
                default   { $item.SubItems[3].ForeColor = [System.Drawing.Color]::DarkOrange }
            }
            $item.Selected = $true
            $item.EnsureVisible()
        }
        Pump-ProgressPanel
    }
    catch {
        $script:panelEnabled = $false
        try { Add-ReportLine "WARN|PANEL_UPDATE||$($_.Exception.Message)" } catch { }
    }
}
function Show-CompletionPanel {
    param(
        [int]$Processed,
        [int]$Failed,
        [bool]$Cancelled = $false
    )
    if (-not $script:panelEnabled -or $script:progressForm.IsDisposed) { return }

    $script:batchComplete = $true
    $successCount = @($script:panelTasks | Where-Object { $_.Success }).Count
    if ($Cancelled) {
        $script:progressBar.Value = [Math]::Min(
            $script:progressBar.Maximum, ($successCount * 100))
        $script:summaryLabel.Text =
            "Ukonczono: $successCount z $($script:panelTasks.Count)    Przerwano: $($script:panelTasks.Count - $successCount)"
        $script:currentLabel.Text = 'Eksport przerwany przez uzytkownika'
        $script:currentLabel.ForeColor = [System.Drawing.Color]::Firebrick
        $script:detailLabel.Text =
            'Zachowano tylko zadania zakonczone i zweryfikowane przed przerwaniem.'
    }
    else {
        $script:progressBar.Value = $script:progressBar.Maximum
        $script:summaryLabel.Text =
            "Wykonano: $Processed z $($script:panelTasks.Count)    Bledy: $Failed    Pozostalo: 0"
        if ($Failed -eq 0) {
            $script:currentLabel.Text = 'Eksport zakonczony poprawnie'
            $script:currentLabel.ForeColor = [System.Drawing.Color]::ForestGreen
            $script:detailLabel.Text = 'Wszystkie wlaczone pliki wynikowe zostaly sprawdzone.'
        }
        else {
            $script:currentLabel.Text = 'Eksport zakonczony z bledami'
            $script:currentLabel.ForeColor = [System.Drawing.Color]::Firebrick
            $script:detailLabel.Text = "Liczba zadan zakonczonych bledem: $Failed"
        }
    }
    $script:cancelButton.Enabled = $false
    $script:closeButton.Enabled = $true
    $script:progressForm.TopMost = $false
    Pump-ProgressPanel

    $seconds = if ($CompletionSeconds -gt 0) {
        $CompletionSeconds
    }
    elseif (-not $Cancelled -and $Failed -eq 0) {
        20
    }
    else {
        45
    }
    while ($seconds -gt 0 -and -not $script:progressForm.IsDisposed) {
        $script:closeButton.Text = "Zamknij ($seconds)"
        Pump-ProgressPanel
        Start-Sleep -Seconds 1
        $seconds--
    }
    if (-not $script:progressForm.IsDisposed) {
        $script:progressForm.Close()
    }
}
function Get-WorkerProgress {
    param([string]$Path)
    if (-not [System.IO.File]::Exists($Path)) { return $null }
    try {
        $text = [System.IO.File]::ReadAllText($Path, $controlEncoding).Trim()
        if ([string]::IsNullOrWhiteSpace($text)) { return $null }
        $parts = $text -split '\|', 3
        if ($parts.Count -lt 3) { return $null }
        $taskIndex = 0
        if (-not [int]::TryParse($parts[0], [ref]$taskIndex)) { return $null }
        return [pscustomobject]@{
            Raw = $text
            Index = $taskIndex
            Code = $parts[1]
            Detail = $parts[2]
        }
    }
    catch {
        return $null
    }
}
function Get-StageStatus {
    param([string]$Code)
    switch ($Code) {
        'OPEN'     { return 'Otwieranie' }
        'PRECHECK' { return 'Sprawdzanie' }
        'FRAME'    { return 'Tworzenie ramek' }
        'MODEL'    { return 'Czyszczenie' }
        'XREF'     { return 'Odnosniki' }
        'PURGE'    { return 'Porzadkowanie' }
        'VERIFY'   { return 'Kontrola' }
        'SAVE'     { return 'Zapis DWG' }
        'WBLOCK'   { return 'Eksport DWG' }
        'PDF'      { return 'Druk PDF' }
        'UNDO'     { return 'Przywracanie' }
        'TASK_OK'  { return 'Gotowe' }
        'TASK_FAIL'{ return 'Blad' }
        'FINAL'    { return 'Finalizacja' }
        default    { return 'Przetwarzanie' }
    }
}

function Copy-SourceWithRetry {
    param(
        [string]$Source,
        [string]$Destination,
        [int]$Attempts = 20
    )
    $lastError = $null
    for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
        try {
            [System.IO.File]::Copy($Source, $Destination, $false)
            return
        }
        catch {
            $lastError = $_.Exception
            if ($attempt -lt $Attempts) {
                Start-Sleep -Milliseconds 500
            }
        }
    }
    throw "Nie mozna skopiowac rysunku zrodlowego: $($lastError.Message)"
}

function Restore-TaskOutput {
    param([object]$Task)
    if (-not $Task.Prepared -or -not $Task.CommitStarted -or $Task.Restored) { return }

    if ($Task.CreateDwg) {
        if (-not $Task.HadDwg -or $Task.BackupDwgReady) {
            try { Remove-FileConfirmed -Path $Task.FinalDwg } catch { }
        }
        if ($Task.BackupDwgReady -and [System.IO.File]::Exists($Task.BackupDwg)) {
            [System.IO.File]::Copy($Task.BackupDwg, $Task.FinalDwg, $true)
        }
    }
    if ($Task.CreatePdf) {
        if (-not $Task.HadPdf -or $Task.BackupPdfReady) {
            try { Remove-FileConfirmed -Path $Task.FinalPdf } catch { }
        }
        if ($Task.BackupPdfReady -and [System.IO.File]::Exists($Task.BackupPdf)) {
            [System.IO.File]::Copy($Task.BackupPdf, $Task.FinalPdf, $true)
        }
    }
    $Task.Restored = $true
}

$tasks = @()
$processed = 0
$failed = 0
$globalFailure = $null
$process = $null
$sessionDir = $null
$tempSource = $null

try {
    foreach ($required in @($BricsExe, $SourceDwg, $Manifest, $WorkerScript)) {
        if (-not [System.IO.File]::Exists($required)) {
            throw "Nie znaleziono wymaganego pliku: $required"
        }
    }

    $rows = [System.IO.File]::ReadAllLines($Manifest, $controlEncoding)
    foreach ($line in $rows) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $parts = $line.Split('|')
        if ($parts.Count -ne 10 -or
            $parts[4] -notin @('0', '1') -or
            $parts[5] -notin @('0', '1') -or
            $parts[7] -notin @('0', '1') -or
            $parts[8] -notin @('0', '1') -or
            $parts[9] -notin @('0', '1') -or
            ($parts[4] -eq '0' -and $parts[5] -eq '0')) {
            throw "Niepoprawny wiersz manifestu: $line"
        }
        $tasks += [pscustomobject]@{
            Layout = $parts[0]
            FinalDwg = $parts[1]
            FinalPdf = $parts[2]
            Pattern = $parts[3]
            CreateDwg = $parts[4] -eq '1'
            CreatePdf = $parts[5] -eq '1'
            IgnoreLayers = $parts[6]
            IgnoreXref = $parts[7] -eq '1'
            PdfFromSource = $parts[8] -eq '1'
            AutoCreateFrames = $parts[9] -eq '1'
            StageDwg = ''
            StagePdf = ''
            HadDwg = $false
            HadPdf = $false
            BackupDwg = ''
            BackupPdf = ''
            BackupDwgReady = $false
            BackupPdfReady = $false
            Prepared = $false
            CommitStarted = $false
            Success = $false
            Restored = $false
            Detail = ''
        }
    }
    if ($tasks.Count -eq 0) {
        throw 'Manifest nie zawiera poprawnych zadan'
    }
    Add-ReportLine "VPOCLIP v3.39-brics|START|tasks=$($tasks.Count)|source=$SourceDwg"

    Initialize-ProgressPanel -Tasks $tasks
    Update-ProgressPanel -Index -1 -Status '' -Stage 'Przygotowanie szybkiego eksportu' `
        -Processed 0 -Failed 0 -Detail "Liczba zadan: $($tasks.Count)"
    if ($script:cancelRequested) {
        throw [System.OperationCanceledException]::new('Przerwano przez uzytkownika')
    }

    $sessionDir = Join-Path ([System.IO.Path]::GetTempPath()) (
        'VPOCLIP_V335_BRICS_' + [guid]::NewGuid().ToString('N'))
    [System.IO.Directory]::CreateDirectory($sessionDir) | Out-Null
    $tempSource = Join-Path $sessionDir 'source.dwg'

    Update-ProgressPanel -Index -1 -Status '' -Stage 'Tworzenie kopii roboczej' `
        -Processed 0 -Failed 0 -Detail 'Kopiowanie rysunku zrodlowego do folderu TEMP'
    if ($script:cancelRequested) {
        throw [System.OperationCanceledException]::new('Przerwano przez uzytkownika')
    }
    Copy-SourceWithRetry -Source $SourceDwg -Destination $tempSource
    if (-not (Test-DwgFile -Path $tempSource)) {
        throw 'Kopia rysunku zrodlowego ma niepoprawna sygnature DWG'
    }

    for ($index = 0; $index -lt $tasks.Count; $index++) {
        Pump-ProgressPanel
        if ($script:cancelRequested) {
            throw [System.OperationCanceledException]::new('Przerwano przez uzytkownika')
        }
        $task = $tasks[$index]
        $targets = @()
        if ($task.CreateDwg) { $targets += $task.FinalDwg }
        if ($task.CreatePdf) { $targets += $task.FinalPdf }
        foreach ($target in $targets) {
            $targetDirectory = [System.IO.Path]::GetDirectoryName($target)
            if ([string]::IsNullOrWhiteSpace($targetDirectory)) {
                throw "Niepoprawny katalog pliku wynikowego: $target"
            }
            [System.IO.Directory]::CreateDirectory($targetDirectory) | Out-Null
        }
        $task.HadDwg = $task.CreateDwg -and [System.IO.File]::Exists($task.FinalDwg)
        $task.HadPdf = $task.CreatePdf -and [System.IO.File]::Exists($task.FinalPdf)
        $task.BackupDwg = Join-Path $sessionDir ("previous_{0:D3}.dwg" -f ($index + 1))
        $task.BackupPdf = Join-Path $sessionDir ("previous_{0:D3}.pdf" -f ($index + 1))
        $task.StageDwg = Join-Path $sessionDir ("result_{0:D3}.dwg" -f ($index + 1))
        $task.StagePdf = Join-Path $sessionDir ("result_{0:D3}.pdf" -f ($index + 1))

        if (($task.HadDwg -or $task.HadPdf) -and $Overwrite -ne 1) {
            throw "Wynik istnieje, a nadpisywanie jest wylaczone: $($task.FinalDwg)"
        }
        if ($task.HadDwg) {
            [System.IO.File]::Copy($task.FinalDwg, $task.BackupDwg, $true)
            $task.BackupDwgReady = $true
        }
        if ($task.HadPdf) {
            [System.IO.File]::Copy($task.FinalPdf, $task.BackupPdf, $true)
            $task.BackupPdfReady = $true
        }
        if ($task.CreateDwg) {
            Remove-LegacyWorkFiles -FinalDwg $task.FinalDwg
        }
        $task.Prepared = $true
    }

    $stageManifest = @($tasks | ForEach-Object {
        "$($_.Layout)|$($_.StageDwg)|$($_.StagePdf)|$($_.Pattern)|$(if ($_.CreateDwg) { '1' } else { '0' })|$(if ($_.CreatePdf) { '1' } else { '0' })|$($_.IgnoreLayers)|$(if ($_.IgnoreXref) { '1' } else { '0' })|$(if ($_.PdfFromSource) { '1' } else { '0' })|$(if ($_.AutoCreateFrames) { '1' } else { '0' })"
    })
    [System.IO.File]::WriteAllLines($Manifest, $stageManifest, $controlEncoding)

    foreach ($path in @($Progress, $Done, $Results)) {
        Remove-FileConfirmed -Path $path
    }

    Update-ProgressPanel -Index 0 -Status 'Start BricsCAD' `
        -Stage "Zadanie 1 z $($tasks.Count): layout $($tasks[0].Layout)" `
        -Processed 0 -Failed 0 -Detail 'Uruchamianie jednej instancji BricsCAD dla calej kolejki' -Code 'OPEN'

    if ($script:cancelRequested) {
        throw [System.OperationCanceledException]::new('Przerwano przez uzytkownika')
    }
    [System.IO.File]::WriteAllText(
        $Progress,
        '1|OPEN|Otwieranie kopii rysunku bez komunikatow proxy' + [Environment]::NewLine,
        $controlEncoding)
    $profileArgument = ''
    if (-not [string]::IsNullOrWhiteSpace($BricsProfile)) {
        $profileArgument = ' /p "' + $BricsProfile.Replace('"', '') + '"'
    }
    $arguments = '/automation /L "' + $tempSource + '"' + $profileArgument +
        ' /b "' + $WorkerScript + '"'
    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $BricsExe
    $startInfo.Arguments = $arguments
    $startInfo.UseShellExecute = $false
    # XREF-y ze sciezkami wzglednymi sa szukane wzgledem folderu zrodla.
    $startInfo.WorkingDirectory = [System.IO.Path]::GetDirectoryName(
        [System.IO.Path]::GetFullPath($SourceDwg))
    $startInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
    $process = [System.Diagnostics.Process]::Start($startInfo)
    if ($null -eq $process) {
        throw 'Nie udalo sie uruchomic niezaleznej instancji BricsCAD'
    }
    $workerWindowHidden = Hide-WorkerMainWindow -Process $process
    $hideDeadline = [DateTime]::UtcNow.AddSeconds(15)
    $nextHideAttempt = [DateTime]::UtcNow.AddSeconds(1)
    $lastProgress = ''
    $liveFailed = 0
    $lastActivity = [DateTime]::UtcNow
    $idleTimedOut = $false

    while (-not [System.IO.File]::Exists($Done) -and
           -not $script:cancelRequested) {
        $process.Refresh()
        if ($process.HasExited) { break }
        $now = [DateTime]::UtcNow
        if (-not $workerWindowHidden -and $now -le $hideDeadline -and
            $now -ge $nextHideAttempt) {
            $workerWindowHidden = Hide-WorkerMainWindow -Process $process
            $nextHideAttempt = $now.AddSeconds(1)
        }

        $workerProgress = Get-WorkerProgress -Path $Progress
        if ($null -ne $workerProgress -and $workerProgress.Raw -ne $lastProgress) {
            $lastProgress = $workerProgress.Raw
            $lastActivity = [DateTime]::UtcNow
            $panelIndex = [Math]::Max(0, [Math]::Min(
                $tasks.Count - 1, $workerProgress.Index - 1))
            $panelProcessed = [Math]::Max(0, $workerProgress.Index - 1)
            $kind = 'Active'
            if ($workerProgress.Code -eq 'TASK_OK') {
                $panelProcessed = $workerProgress.Index
                $kind = 'Success'
            }
            elseif ($workerProgress.Code -eq 'TASK_FAIL') {
                $panelProcessed = $workerProgress.Index
                $liveFailed++
                $kind = 'Error'
            }
            Update-ProgressPanel -Index $panelIndex `
                -Status (Get-StageStatus -Code $workerProgress.Code) `
                -Stage "Zadanie $($workerProgress.Index) z $($tasks.Count): layout $($tasks[$panelIndex].Layout)" `
                -Processed $panelProcessed -Failed $liveFailed `
                -Detail $workerProgress.Detail -Kind $kind -Code $workerProgress.Code
        }
        if (([DateTime]::UtcNow - $lastActivity).TotalSeconds -ge $IdleTimeoutSeconds) {
            $idleTimedOut = $true
            break
        }
        Pump-ProgressPanel
        if ($script:cancelRequested) { break }
        Start-Sleep -Milliseconds 300
    }

    if ($script:cancelRequested) {
        $globalFailure = 'Przerwano przez uzytkownika'
        Add-ReportLine "CANCEL|CONTROLLER||$globalFailure"
    }
    elseif (-not [System.IO.File]::Exists($Done)) {
        $globalFailure = if ($idleTimedOut) {
            "BricsCAD nie zglosil postepu przez $IdleTimeoutSeconds s"
        }
        else {
            'BricsCAD zakonczyl sie przed potwierdzeniem calej kolejki'
        }
        Add-ReportLine "FAIL|CONTROLLER||$globalFailure"
    }

    Update-ProgressPanel -Index ($tasks.Count - 1) `
        -Status $(if ($script:cancelRequested) { 'Przerwano' } else { 'Zamykanie' }) `
        -Stage $(if ($script:cancelRequested) { 'Przerywanie eksportu' } else { 'Finalizacja szybkiego eksportu' }) `
        -Processed ($tasks.Count - 1) -Failed 0 `
        -Detail $(if ($globalFailure) { $globalFailure } else { 'Zamykanie jedynej instancji BricsCAD' })
    Stop-WorkerProcess -Process $process -Immediate:$script:cancelRequested
    $process = $null

    $resultMap = @{}
    if ([System.IO.File]::Exists($Results)) {
        foreach ($line in [System.IO.File]::ReadAllLines($Results, $controlEncoding)) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            $parts = $line -split '\|', 4
            if ($parts.Count -ge 3) {
                $resultMap[$parts[0]] = [pscustomobject]@{
                    Status = $parts[1]
                    Layout = $parts[2]
                    Detail = $(if ($parts.Count -gt 3) { $parts[3] } else { '' })
                }
            }
        }
    }
    elseif ([string]::IsNullOrWhiteSpace($globalFailure)) {
        $globalFailure = 'Brak pliku wynikow z procesu BricsCAD'
        Add-ReportLine "FAIL|CONTROLLER||$globalFailure"
    }

    for ($index = 0; $index -lt $tasks.Count; $index++) {
        Pump-ProgressPanel
        $task = $tasks[$index]
        $key = ($index + 1).ToString()
        $result = $resultMap[$key]
        $detail = if ($null -ne $result) { $result.Detail } else { 'brak wyniku zadania' }
        $valid = $null -ne $result -and $result.Status -eq 'OK' -and
            (-not $task.CreateDwg -or (Test-DwgFile -Path $task.StageDwg)) -and
            (-not $task.CreatePdf -or (Test-PdfFile -Path $task.StagePdf))

        $processed++
        if ($valid) {
            try {
                $task.CommitStarted = $true
                if ($task.CreateDwg) {
                    Remove-FileConfirmed -Path $task.FinalDwg
                    [System.IO.File]::Copy($task.StageDwg, $task.FinalDwg, $false)
                }
                if ($task.CreatePdf) {
                    Remove-FileConfirmed -Path $task.FinalPdf
                    [System.IO.File]::Copy($task.StagePdf, $task.FinalPdf, $false)
                }
                if (($task.CreateDwg -and -not (Test-DwgFile -Path $task.FinalDwg)) -or
                    ($task.CreatePdf -and -not (Test-PdfFile -Path $task.FinalPdf))) {
                    throw 'walidacja plikow docelowych nie powiodla sie'
                }
                $task.Success = $true
                $formats = @()
                if ($task.CreateDwg) { $formats += 'DWG' }
                if ($task.CreatePdf) { $formats += 'PDF' }
                $task.Detail = (($formats -join ' i ') + ' zapisane poprawnie')
                $reportDwg = if ($task.CreateDwg) { $task.FinalDwg } else { '-' }
                $reportPdf = if ($task.CreatePdf) { $task.FinalPdf } else { '-' }
                Add-ReportLine "OK|$($task.Layout)|$reportDwg|$reportPdf"
                Update-ProgressPanel -Index $index -Status 'Gotowe' `
                    -Stage "Zakonczono layout $($task.Layout)" `
                    -Processed $processed -Failed $failed `
                    -Detail $task.Detail -Kind 'Success'
            }
            catch {
                $valid = $false
                $detail = "nie mozna zapisac plikow docelowych: $($_.Exception.Message)"
            }
        }
        if (-not $valid) {
            $failed++
            $detail = if ($script:cancelRequested -and $null -eq $result) {
                'przerwano przez uzytkownika'
            }
            else {
                $detail
            }
            $task.Detail = $detail
            Restore-TaskOutput -Task $task
            if ($script:cancelRequested -and $null -eq $result) {
                Add-ReportLine "CANCEL|$($task.Layout)|$($task.FinalDwg)|$detail"
                Update-ProgressPanel -Index $index -Status 'Przerwano' `
                    -Stage "Pominieto layout $($task.Layout)" `
                    -Processed $processed -Failed $failed `
                    -Detail $detail -Kind 'Error'
            }
            else {
                Add-ReportLine "FAIL|$($task.Layout)|$($task.FinalDwg)|$detail"
                Update-ProgressPanel -Index $index -Status 'Blad' `
                    -Stage "Blad layoutu $($task.Layout)" `
                    -Processed $processed -Failed $failed `
                    -Detail $detail -Kind 'Error'
            }
        }
    }
}
catch {
    $globalFailure = $_.Exception.Message
    if ($null -ne $process) {
        Stop-WorkerProcess -Process $process -Immediate:$script:cancelRequested
        $process = $null
    }
    $failed = [Math]::Max($failed, $tasks.Count)
    if ($script:cancelRequested) {
        try { Add-ReportLine "CANCEL|CONTROLLER||$globalFailure" } catch { }
        if ($script:panelEnabled) {
            Update-ProgressPanel -Index -1 -Status 'Przerwano' `
                -Stage 'Przerywanie eksportu' `
                -Processed $processed -Failed $failed `
                -Detail $globalFailure -Kind 'Error'
        }
    }
    else {
        try { Add-ReportLine "FAIL|CONTROLLER||$globalFailure" } catch { }
        if ($script:panelEnabled) {
            Update-ProgressPanel -Index -1 -Status 'Blad' `
                -Stage 'Blad kontrolera szybkiego eksportu' `
                -Processed $processed -Failed $failed `
                -Detail $globalFailure -Kind 'Error'
        }
    }
}
finally {
    if ($null -ne $process) {
        Stop-WorkerProcess -Process $process -Immediate:$script:cancelRequested
    }
    foreach ($task in $tasks) {
        if ($task.Prepared -and -not $task.Success) {
            try { Restore-TaskOutput -Task $task } catch { }
        }
        foreach ($backup in @($task.BackupDwg, $task.BackupPdf)) {
            try { Remove-FileConfirmed -Path $backup } catch { }
        }
        if ($task.CreateDwg) {
            Remove-LegacyWorkFiles -FinalDwg $task.FinalDwg
        }
    }
    foreach ($path in @($Manifest, $WorkerScript, $Progress, $Done, $Results)) {
        try { Remove-FileConfirmed -Path $path } catch { }
    }
    try {
        if ($sessionDir -and [System.IO.Directory]::Exists($sessionDir)) {
            [System.IO.Directory]::Delete($sessionDir, $true)
        }
    }
    catch { }
    try { Add-BatchEnd } catch { }
    Show-CompletionPanel -Processed $processed -Failed $failed `
        -Cancelled $script:cancelRequested
}
