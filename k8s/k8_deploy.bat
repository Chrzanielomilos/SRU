@echo off
setlocal enabledelayedexpansion

REM Użycie:
REM   deploy.bat         - pełne wdrożenie (backend + frontend)
REM   deploy.bat b       - tylko backend
REM   deploy.bat f       - tylko frontend

REM Parsowanie argumentów
set "target=all"
if "%~1"=="" (
    set "target=all"
) else (
    if /I "%~1"=="b" (
        set "target=backend"
    ) else if /I "%~1"=="f" (
        set "target=frontend"
    ) else (
        echo [BŁĄD] Nieznany argument: %~1
        echo Użycie:
        echo   %~nx0           - pełne wdrożenie
        echo   %~nx0 b         - tylko backend
        echo   %~nx0 f         - tylko frontend
        pause
        exit /b 1
    )
)

REM Funkcja usuwania backendu
call :cleanup_backend
goto :continue

:cleanup_backend
if "%target%"=="all" (
    echo ========================================
    echo Usuwanie backendu...
    echo ========================================
    docker rm -f sru-backend 2>nul
    docker rmi sru-backend:latest 2>nul
)
if "%target%"=="backend" (
    echo ========================================
    echo Usuwanie backendu...
    echo ========================================
    docker rm -f sru-backend 2>nul
    docker rmi sru-backend:latest 2>nul
)
goto :eof

:continue

REM Usuwanie frontendu
if "%target%"=="all" (
    echo ========================================
    echo Usuwanie frontendu...
    echo ========================================
    docker rm -f sru-frontend 2>nul
    docker rmi sru-frontend:latest 2>nul
)
if "%target%"=="frontend" (
    echo ========================================
    echo Usuwanie frontendu...
    echo ========================================
    docker rm -f sru-frontend 2>nul
    docker rmi sru-frontend:latest 2>nul
)

REM Budowanie backendu
if "%target%"=="all" (
    echo ========================================
    echo Budowanie backendu...
    echo ========================================
    docker build -t sru-backend:latest ./backend
    if errorlevel 1 (
        echo [BŁĄD] Budowanie backendu nie powiodlo sie.
        pause
        exit /b 1
    )
)
if "%target%"=="backend" (
    echo ========================================
    echo Budowanie backendu...
    echo ========================================
    docker build -t sru-backend:latest ./backend
    if errorlevel 1 (
        echo [BŁĄD] Budowanie backendu nie powiodlo sie.
        pause
        exit /b 1
    )
)

REM Budowanie frontendu
if "%target%"=="all" (
    echo ========================================
    echo Budowanie frontendu...
    echo ========================================
    docker build -t sru-frontend:latest ./frontend
    if errorlevel 1 (
        echo [BŁĄD] Budowanie frontendu nie powiodlo sie.
        pause
        exit /b 1
    )
)
if "%target%"=="frontend" (
    echo ========================================
    echo Budowanie frontendu...
    echo ========================================
    docker build -t sru-frontend:latest ./frontend
    if errorlevel 1 (
        echo [BŁĄD] Budowanie frontendu nie powiodlo sie.
        pause
        exit /b 1
    )
)

REM Wdrażanie do Kubernetes (dla każdego przypadku)
echo ========================================
echo Wdrażanie do Kubernetes...
echo ========================================
kubectl apply -f k8s/
if errorlevel 1 (
    echo [BŁĄD] Wdrażanie do Kubernetes nie powiodlo sie.
    pause
    exit /b 1
)

echo ========================================
echo ✅ Nowa wersja wdrozona pomyslnie!
echo ========================================
pause
