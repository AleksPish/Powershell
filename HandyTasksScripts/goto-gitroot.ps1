function croot {
      $root = git rev-parse --show-toplevel 2>$null
      if ($LASTEXITCODE -eq 0 -and $root) {
          Set-Location $root
      } else {
          Write-Host "Not inside a git repository."
      }
  }