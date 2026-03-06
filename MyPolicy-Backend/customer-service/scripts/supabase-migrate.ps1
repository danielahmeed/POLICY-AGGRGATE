param(
    [string]$LocalHost = "localhost",
    [int]$LocalPort = 5432,
    [string]$LocalDb = "mypolicy_db",
    [string]$LocalUser = "postgres",

    [string]$SupabaseHost = "db.httmoactttxwwqjvahqc.supabase.co",
    [int]$SupabasePort = 5432,
    [string]$SupabaseDb = "postgres",
    [string]$SupabaseUser = "postgres",

    [string]$DumpFile = "./mypolicy_db.sql",

    [string]$LocalPassword,
    [string]$SupabasePassword
)

$ErrorActionPreference = "Stop"

function Get-PlainTextFromSecureString {
    param([securestring]$Secure)
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    }
}

function Ensure-Command {
    param([string]$Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command '$Name' not found in PATH. Install PostgreSQL client tools (pg_dump, psql)."
    }
}

Ensure-Command "pg_dump"
Ensure-Command "psql"

if ([string]::IsNullOrWhiteSpace($LocalPassword)) {
    $secure = Read-Host "Enter LOCAL PostgreSQL password for user '$LocalUser'" -AsSecureString
    $LocalPassword = Get-PlainTextFromSecureString -Secure $secure
}

if ([string]::IsNullOrWhiteSpace($SupabasePassword)) {
    $secure = Read-Host "Enter SUPABASE PostgreSQL password for user '$SupabaseUser'" -AsSecureString
    $SupabasePassword = Get-PlainTextFromSecureString -Secure $secure
}

Write-Host "[1/2] Exporting local database '$LocalDb' from ${LocalHost}:${LocalPort} ..." -ForegroundColor Cyan
$env:PGPASSWORD = $LocalPassword
& pg_dump -h $LocalHost -p $LocalPort -U $LocalUser -d $LocalDb --no-owner --no-privileges -f $DumpFile
if ($LASTEXITCODE -ne 0) {
    throw "pg_dump failed with exit code $LASTEXITCODE"
}

Write-Host "[2/2] Importing dump into Supabase '$SupabaseDb' on ${SupabaseHost}:${SupabasePort} ..." -ForegroundColor Cyan
$env:PGPASSWORD = $SupabasePassword
$env:PGSSLMODE = "require"
& psql -h $SupabaseHost -p $SupabasePort -U $SupabaseUser -d $SupabaseDb -v "ON_ERROR_STOP=1" -f $DumpFile
if ($LASTEXITCODE -ne 0) {
    throw "psql import failed with exit code $LASTEXITCODE"
}

Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
Remove-Item Env:PGSSLMODE -ErrorAction SilentlyContinue
Write-Host "Migration completed successfully." -ForegroundColor Green
Write-Host "Dump file: $DumpFile"
