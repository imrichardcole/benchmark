
$BuildDir="build"
$Tag="v1.9.0"
$VenvDir=".venv"
$RootDir=$PSScriptRoot
$Jobs=4
$Reports="reports"

Remove-Item -LiteralPath $BuildDir -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $Tag -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $VenvDir -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $Reports -Force -Recurse -ErrorAction SilentlyContinue
New-Item -Path $Reports -ItemType Directory | Out-Null

Write-Host "****** setting up venv for python dependencies (junit2html) ******" -ForegroundColor Green
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install junit2html
Write-Host "****** finished up venv for python dependencies (junit2html) ******" -ForegroundColor Green

$ToolChains = @('v140', 'v141', 'v142', 'v143')

foreach ( $ToolChain in $ToolChains )
{
    Write-Host "****** building toolchain $($ToolChain) ******" -ForegroundColor Green
    cmake -S . -B $BuildDir/$ToolChain -DBENCHMARK_ENABLE_GTEST_TESTS=FALSE -DCMAKE_INSTALL_PREFIX="$($RootDir)/install/benchmark/$($Tag)/$($ToolChain)" | Tee-Object -file "$($Reports)/$($ToolChain)_configure.log"
    cmake --build $BuildDir/$ToolChain --config Release --target install -j "$($Jobs)" --verbose  | Tee-Object -file "$($Reports)/$($ToolChain)_build.log"
    ctest --test-dir $BuildDir/$ToolChain -C Release -j $($Jobs) --output-junit "$($ToolChain)_tests.xml"
    junit2html "build/$($ToolChain)/$($ToolChain)_tests.xml" "$($Reports)/$($ToolChain)_test_results.html"
    Write-Host "****** finished toolchain $($ToolChain) ******" -ForegroundColor Green
}

deactivate
