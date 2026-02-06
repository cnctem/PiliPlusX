# Dart Dot-Shorthand Syntax Fix Script
# Fixes Dart 3.9+ dot-shorthand syntax to be compatible with older SDK versions
# Usage: .\fix_dart_dot_shorthand.ps1

Write-Host "Starting Dart dot-shorthand fix..." -ForegroundColor Green

$replacements = @(
    # MainAxisSize
    @{ Pattern = 'mainAxisSize:\s*\.min'; Replacement = 'mainAxisSize: MainAxisSize.min'; Description = 'MainAxisSize.min' }
    @{ Pattern = 'mainAxisSize:\s*\.max'; Replacement = 'mainAxisSize: MainAxisSize.max'; Description = 'MainAxisSize.max' }
    
    # CrossAxisAlignment
    @{ Pattern = 'crossAxisAlignment:\s*\.start'; Replacement = 'crossAxisAlignment: CrossAxisAlignment.start'; Description = 'CrossAxisAlignment.start' }
    @{ Pattern = 'crossAxisAlignment:\s*\.end'; Replacement = 'crossAxisAlignment: CrossAxisAlignment.end'; Description = 'CrossAxisAlignment.end' }
    @{ Pattern = 'crossAxisAlignment:\s*\.center'; Replacement = 'crossAxisAlignment: CrossAxisAlignment.center'; Description = 'CrossAxisAlignment.center' }
    @{ Pattern = 'crossAxisAlignment:\s*\.stretch'; Replacement = 'crossAxisAlignment: CrossAxisAlignment.stretch'; Description = 'CrossAxisAlignment.stretch' }
    @{ Pattern = 'crossAxisAlignment:\s*\.baseline'; Replacement = 'crossAxisAlignment: CrossAxisAlignment.baseline'; Description = 'CrossAxisAlignment.baseline' }
    
    # MainAxisAlignment
    @{ Pattern = 'mainAxisAlignment:\s*\.start'; Replacement = 'mainAxisAlignment: MainAxisAlignment.start'; Description = 'MainAxisAlignment.start' }
    @{ Pattern = 'mainAxisAlignment:\s*\.end'; Replacement = 'mainAxisAlignment: MainAxisAlignment.end'; Description = 'MainAxisAlignment.end' }
    @{ Pattern = 'mainAxisAlignment:\s*\.center'; Replacement = 'mainAxisAlignment: MainAxisAlignment.center'; Description = 'MainAxisAlignment.center' }
    @{ Pattern = 'mainAxisAlignment:\s*\.spaceBetween'; Replacement = 'mainAxisAlignment: MainAxisAlignment.spaceBetween'; Description = 'MainAxisAlignment.spaceBetween' }
    @{ Pattern = 'mainAxisAlignment:\s*\.spaceAround'; Replacement = 'mainAxisAlignment: MainAxisAlignment.spaceAround'; Description = 'MainAxisAlignment.spaceAround' }
    @{ Pattern = 'mainAxisAlignment:\s*\.spaceEvenly'; Replacement = 'mainAxisAlignment: MainAxisAlignment.spaceEvenly'; Description = 'MainAxisAlignment.spaceEvenly' }
    
    # TextOverflow
    @{ Pattern = 'overflow:\s*\.ellipsis'; Replacement = 'overflow: TextOverflow.ellipsis'; Description = 'TextOverflow.ellipsis' }
    @{ Pattern = 'overflow:\s*\.clip'; Replacement = 'overflow: TextOverflow.clip'; Description = 'TextOverflow.clip' }
    @{ Pattern = 'overflow:\s*\.fade'; Replacement = 'overflow: TextOverflow.fade'; Description = 'TextOverflow.fade' }
    @{ Pattern = 'overflow:\s*\.visible'; Replacement = 'overflow: TextOverflow.visible'; Description = 'TextOverflow.visible' }
    
    # ImageType (project specific)
    @{ Pattern = 'type:\s*\.emote'; Replacement = 'type: ImageType.emote'; Description = 'ImageType.emote' }
    @{ Pattern = 'type:\s*\.avatar'; Replacement = 'type: ImageType.avatar'; Description = 'ImageType.avatar' }
    @{ Pattern = 'type:\s*\.video'; Replacement = 'type: ImageType.video'; Description = 'ImageType.video' }
    @{ Pattern = 'type:\s*\.live'; Replacement = 'type: ImageType.live'; Description = 'ImageType.live' }
    
    # EdgeInsets
    @{ Pattern = 'const\s+\.only\('; Replacement = 'const EdgeInsets.only('; Description = 'EdgeInsets.only' }
    @{ Pattern = 'const\s+\.all\('; Replacement = 'const EdgeInsets.all('; Description = 'EdgeInsets.all' }
    @{ Pattern = 'const\s+\.symmetric\('; Replacement = 'const EdgeInsets.symmetric('; Description = 'EdgeInsets.symmetric' }
    @{ Pattern = 'const\s+\.fromLTRB\('; Replacement = 'const EdgeInsets.fromLTRB('; Description = 'EdgeInsets.fromLTRB' }
    @{ Pattern = 'padding:\s*\.zero(?!\w)'; Replacement = 'padding: EdgeInsets.zero'; Description = 'EdgeInsets.zero (padding)' }
    @{ Pattern = 'margin:\s*\.zero(?!\w)'; Replacement = 'margin: EdgeInsets.zero'; Description = 'EdgeInsets.zero (margin)' }
    
    # BorderRadius
    @{ Pattern = 'const\s+\.circular\('; Replacement = 'const BorderRadius.circular('; Description = 'BorderRadius.circular' }
    @{ Pattern = ':\s*const\s+\.only\(\s*topLeft:\s*\.circular'; Replacement = ': const BorderRadius.only(topLeft: Radius.circular'; Description = 'BorderRadius.only with Radius.circular' }
    @{ Pattern = 'topRight:\s*\.circular'; Replacement = 'topRight: Radius.circular'; Description = 'Radius.circular (topRight)' }
    @{ Pattern = 'bottomLeft:\s*\.circular'; Replacement = 'bottomLeft: Radius.circular'; Description = 'Radius.circular (bottomLeft)' }
    @{ Pattern = 'bottomRight:\s*\.circular'; Replacement = 'bottomRight: Radius.circular'; Description = 'Radius.circular (bottomRight)' }
    @{ Pattern = 'topLeft:\s*\.circular'; Replacement = 'topLeft: Radius.circular'; Description = 'Radius.circular (topLeft)' }
    
    # Axis
    @{ Pattern = 'scrollDirection:\s*\.horizontal'; Replacement = 'scrollDirection: Axis.horizontal'; Description = 'Axis.horizontal' }
    @{ Pattern = 'scrollDirection:\s*\.vertical'; Replacement = 'scrollDirection: Axis.vertical'; Description = 'Axis.vertical' }
    @{ Pattern = 'direction:\s*\.horizontal'; Replacement = 'direction: Axis.horizontal'; Description = 'Axis.horizontal (direction)' }
    @{ Pattern = 'direction:\s*\.vertical'; Replacement = 'direction: Axis.vertical'; Description = 'Axis.vertical (direction)' }
    
    # PlaceholderAlignment
    @{ Pattern = 'alignment:\s*\.middle'; Replacement = 'alignment: PlaceholderAlignment.middle'; Description = 'PlaceholderAlignment.middle' }
    @{ Pattern = 'alignment:\s*\.top'; Replacement = 'alignment: PlaceholderAlignment.top'; Description = 'PlaceholderAlignment.top' }
    @{ Pattern = 'alignment:\s*\.bottom'; Replacement = 'alignment: PlaceholderAlignment.bottom'; Description = 'PlaceholderAlignment.bottom' }
    @{ Pattern = 'alignment:\s*\.baseline'; Replacement = 'alignment: PlaceholderAlignment.baseline'; Description = 'PlaceholderAlignment.baseline' }
    @{ Pattern = 'alignment:\s*\.aboveBaseline'; Replacement = 'alignment: PlaceholderAlignment.aboveBaseline'; Description = 'PlaceholderAlignment.aboveBaseline' }
    @{ Pattern = 'alignment:\s*\.belowBaseline'; Replacement = 'alignment: PlaceholderAlignment.belowBaseline'; Description = 'PlaceholderAlignment.belowBaseline' }
    
    # HitTestBehavior
    @{ Pattern = 'behavior:\s*\.opaque'; Replacement = 'behavior: HitTestBehavior.opaque'; Description = 'HitTestBehavior.opaque' }
    @{ Pattern = 'behavior:\s*\.translucent'; Replacement = 'behavior: HitTestBehavior.translucent'; Description = 'HitTestBehavior.translucent' }
    @{ Pattern = 'behavior:\s*\.deferToChild'; Replacement = 'behavior: HitTestBehavior.deferToChild'; Description = 'HitTestBehavior.deferToChild' }
    
    # Clip
    @{ Pattern = 'clipBehavior:\s*\.hardEdge'; Replacement = 'clipBehavior: Clip.hardEdge'; Description = 'Clip.hardEdge' }
    @{ Pattern = 'clipBehavior:\s*\.antiAlias'; Replacement = 'clipBehavior: Clip.antiAlias'; Description = 'Clip.antiAlias' }
    @{ Pattern = 'clipBehavior:\s*\.antiAliasWithSaveLayer'; Replacement = 'clipBehavior: Clip.antiAliasWithSaveLayer'; Description = 'Clip.antiAliasWithSaveLayer' }
    @{ Pattern = 'clipBehavior:\s*\.none'; Replacement = 'clipBehavior: Clip.none'; Description = 'Clip.none' }
    @{ Pattern = 'clip:\s*\.hardEdge'; Replacement = 'clip: Clip.hardEdge'; Description = 'Clip.hardEdge (clip)' }
    @{ Pattern = 'clip:\s*\.antiAlias'; Replacement = 'clip: Clip.antiAlias'; Description = 'Clip.antiAlias (clip)' }
    @{ Pattern = 'clip:\s*\.none'; Replacement = 'clip: Clip.none'; Description = 'Clip.none (clip)' }
    
    # BoxFit
    @{ Pattern = 'fit:\s*\.cover'; Replacement = 'fit: BoxFit.cover'; Description = 'BoxFit.cover' }
    @{ Pattern = 'fit:\s*\.contain'; Replacement = 'fit: BoxFit.contain'; Description = 'BoxFit.contain' }
    @{ Pattern = 'fit:\s*\.fill'; Replacement = 'fit: BoxFit.fill'; Description = 'BoxFit.fill' }
    @{ Pattern = 'fit:\s*\.fitWidth'; Replacement = 'fit: BoxFit.fitWidth'; Description = 'BoxFit.fitWidth' }
    @{ Pattern = 'fit:\s*\.fitHeight'; Replacement = 'fit: BoxFit.fitHeight'; Description = 'BoxFit.fitHeight' }
    @{ Pattern = 'fit:\s*\.none'; Replacement = 'fit: BoxFit.none'; Description = 'BoxFit.none' }
    @{ Pattern = 'fit:\s*\.scaleDown'; Replacement = 'fit: BoxFit.scaleDown'; Description = 'BoxFit.scaleDown' }
    
    # BoxShape
    @{ Pattern = 'shape:\s*\.circle'; Replacement = 'shape: BoxShape.circle'; Description = 'BoxShape.circle' }
    @{ Pattern = 'shape:\s*\.rectangle'; Replacement = 'shape: BoxShape.rectangle'; Description = 'BoxShape.rectangle' }
    
    # TextAlign
    @{ Pattern = 'textAlign:\s*\.center'; Replacement = 'textAlign: TextAlign.center'; Description = 'TextAlign.center' }
    @{ Pattern = 'textAlign:\s*\.left'; Replacement = 'textAlign: TextAlign.left'; Description = 'TextAlign.left' }
    @{ Pattern = 'textAlign:\s*\.right'; Replacement = 'textAlign: TextAlign.right'; Description = 'TextAlign.right' }
    @{ Pattern = 'textAlign:\s*\.start'; Replacement = 'textAlign: TextAlign.start'; Description = 'TextAlign.start' }
    @{ Pattern = 'textAlign:\s*\.end'; Replacement = 'textAlign: TextAlign.end'; Description = 'TextAlign.end' }
    @{ Pattern = 'textAlign:\s*\.justify'; Replacement = 'textAlign: TextAlign.justify'; Description = 'TextAlign.justify' }
    
    # TextScaler
    @{ Pattern = 'textScaler:\s*\.noScaling'; Replacement = 'textScaler: TextScaler.noScaling'; Description = 'TextScaler.noScaling' }
    
    # VisualDensity
    @{ Pattern = 'visualDensity:\s*\.standard'; Replacement = 'visualDensity: VisualDensity.standard'; Description = 'VisualDensity.standard' }
    @{ Pattern = 'visualDensity:\s*\.compact'; Replacement = 'visualDensity: VisualDensity.compact'; Description = 'VisualDensity.compact' }
    @{ Pattern = 'visualDensity:\s*\.comfortable'; Replacement = 'visualDensity: VisualDensity.comfortable'; Description = 'VisualDensity.comfortable' }
    @{ Pattern = 'visualDensity:\s*\.adaptivePlatformDensity'; Replacement = 'visualDensity: VisualDensity.adaptivePlatformDensity'; Description = 'VisualDensity.adaptivePlatformDensity' }
    
    # MaterialTapTargetSize
    @{ Pattern = 'tapTargetSize:\s*\.padded'; Replacement = 'tapTargetSize: MaterialTapTargetSize.padded'; Description = 'MaterialTapTargetSize.padded' }
    @{ Pattern = 'tapTargetSize:\s*\.shrinkWrap'; Replacement = 'tapTargetSize: MaterialTapTargetSize.shrinkWrap'; Description = 'MaterialTapTargetSize.shrinkWrap' }
    
    # MaterialType
    @{ Pattern = 'type:\s*\.transparency'; Replacement = 'type: MaterialType.transparency'; Description = 'MaterialType.transparency' }
    @{ Pattern = 'type:\s*\.canvas'; Replacement = 'type: MaterialType.canvas'; Description = 'MaterialType.canvas' }
    @{ Pattern = 'type:\s*\.card'; Replacement = 'type: MaterialType.card'; Description = 'MaterialType.card' }
    
    # double/Size/Offset/Radius/Duration
    @{ Pattern = 'width:\s*\.infinity'; Replacement = 'width: double.infinity'; Description = 'double.infinity (width)' }
    @{ Pattern = 'height:\s*\.infinity'; Replacement = 'height: double.infinity'; Description = 'double.infinity (height)' }
    @{ Pattern = '=\s*\.infinity'; Replacement = '= double.infinity'; Description = 'double.infinity' }
    @{ Pattern = 'size:\s*\.zero(?!\w)'; Replacement = 'size: Size.zero'; Description = 'Size.zero' }
    @{ Pattern = 'offset:\s*\.zero(?!\w)'; Replacement = 'offset: Offset.zero'; Description = 'Offset.zero' }
    @{ Pattern = 'radius:\s*\.zero(?!\w)'; Replacement = 'radius: Radius.zero'; Description = 'Radius.zero' }
    @{ Pattern = 'duration:\s*\.zero(?!\w)'; Replacement = 'duration: Duration.zero'; Description = 'Duration.zero' }
    
    # RelativeRect
    @{ Pattern = 'position:\s*\.fromLTRB\('; Replacement = 'position: RelativeRect.fromLTRB('; Description = 'RelativeRect.fromLTRB' }
    
    # Brightness
    @{ Pattern = 'brightness:\s*\.light'; Replacement = 'brightness: Brightness.light'; Description = 'Brightness.light' }
    @{ Pattern = 'brightness:\s*\.dark'; Replacement = 'brightness: Brightness.dark'; Description = 'Brightness.dark' }
    
    # Colors (common colors)
    @{ Pattern = 'const\s+\.white(?!\w)'; Replacement = 'const Colors.white'; Description = 'Colors.white' }
    @{ Pattern = 'const\s+\.black(?!\w)'; Replacement = 'const Colors.black'; Description = 'Colors.black' }
    @{ Pattern = 'const\s+\.red(?!\w)'; Replacement = 'const Colors.red'; Description = 'Colors.red' }
    @{ Pattern = 'const\s+\.blue(?!\w)'; Replacement = 'const Colors.blue'; Description = 'Colors.blue' }
    @{ Pattern = 'const\s+\.green(?!\w)'; Replacement = 'const Colors.green'; Description = 'Colors.green' }
    @{ Pattern = 'const\s+\.yellow(?!\w)'; Replacement = 'const Colors.yellow'; Description = 'Colors.yellow' }
    @{ Pattern = 'const\s+\.transparent(?!\w)'; Replacement = 'const Colors.transparent'; Description = 'Colors.transparent' }
    @{ Pattern = 'const\s+\.grey(?!\w)'; Replacement = 'const Colors.grey'; Description = 'Colors.grey' }
    @{ Pattern = 'const\s+\.orange(?!\w)'; Replacement = 'const Colors.orange'; Description = 'Colors.orange' }
    @{ Pattern = 'const\s+\.purple(?!\w)'; Replacement = 'const Colors.purple'; Description = 'Colors.purple' }
    @{ Pattern = 'const\s+\.pink(?!\w)'; Replacement = 'const Colors.pink'; Description = 'Colors.pink' }
    @{ Pattern = 'const\s+\.teal(?!\w)'; Replacement = 'const Colors.teal'; Description = 'Colors.teal' }
    @{ Pattern = 'const\s+\.cyan(?!\w)'; Replacement = 'const Colors.cyan'; Description = 'Colors.cyan' }
    @{ Pattern = 'const\s+\.indigo(?!\w)'; Replacement = 'const Colors.indigo'; Description = 'Colors.indigo' }
    @{ Pattern = 'const\s+\.lime(?!\w)'; Replacement = 'const Colors.lime'; Description = 'Colors.lime' }
    @{ Pattern = 'const\s+\.amber(?!\w)'; Replacement = 'const Colors.amber'; Description = 'Colors.amber' }
    @{ Pattern = 'const\s+\.brown(?!\w)'; Replacement = 'const Colors.brown'; Description = 'Colors.brown' }
)

# Get all Dart files
if (-not (Test-Path "lib")) {
    Write-Host "ERROR: lib directory not found. Please run this script from Flutter/Dart project root." -ForegroundColor Red
    exit 1
}

$dartFiles = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse

$totalFiles = 0
$totalReplacements = 0
$replacementDetails = @{}

Write-Host "`nScanning $($dartFiles.Count) Dart files..." -ForegroundColor Cyan

foreach ($file in $dartFiles) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    $originalContent = $content
    $fileChanged = $false
    $fileReplacements = 0
    
    foreach ($rep in $replacements) {
        $matches = [regex]::Matches($content, $rep.Pattern)
        if ($matches.Count -gt 0) {
            $content = $content -replace $rep.Pattern, $rep.Replacement
            $fileChanged = $true
            $fileReplacements += $matches.Count
            $totalReplacements += $matches.Count
            
            # Record replacement details
            if (-not $replacementDetails.ContainsKey($rep.Description)) {
                $replacementDetails[$rep.Description] = 0
            }
            $replacementDetails[$rep.Description] += $matches.Count
        }
    }
    
    if ($fileChanged) {
        Set-Content -Path $file.FullName -Value $content -Encoding UTF8 -NoNewline
        $totalFiles++
        $relativePath = $file.FullName.Replace((Get-Location).Path + "\", "")
        Write-Host "  [OK] $relativePath ($fileReplacements changes)" -ForegroundColor Green
    }
}

Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "Fix completed!" -ForegroundColor Green
Write-Host "="*60 -ForegroundColor Cyan
Write-Host "Files modified: $totalFiles" -ForegroundColor Yellow
Write-Host "Total replacements: $totalReplacements" -ForegroundColor Yellow

if ($replacementDetails.Count -gt 0) {
    Write-Host "`nReplacement details:" -ForegroundColor Cyan
    $replacementDetails.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
        Write-Host "  - $($_.Key): $($_.Value) times" -ForegroundColor Gray
    }
}

Write-Host "`nRecommend running 'dart analyze' to verify the fixes." -ForegroundColor Cyan
