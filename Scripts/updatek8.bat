@echo off
setlocal enabledelayedexpansion

:: Domyślne wartości
set "DEPLOYMENT=django-deployment"
set "NAMESPACE=default"

:: Argumenty (opcjonalne): updatek8s.bat <deployment> <namespace> [push]
if not "%~1"=="" set "DEPLOYMENT=%~1"
if not "%~2"=="" set "NAMESPACE=%~2"
set "DO_PUSH=%~3"

:: Pobierz aktualny obraz (pełna wartość image, np. repo/app:tag)
for /f "delims=" %%i in ('kubectl get deploy %DEPLOYMENT% -n %NAMESPACE% -o "jsonpath={.spec.template.spec.containers[0].image}"') do (
  set "IMAGE=%%i"
)

:: Pobierz nazwę kontenera
for /f "delims=" %%i in ('kubectl get deploy %DEPLOYMENT% -n %NAMESPACE% -o "jsonpath={.spec.template.spec.containers[0].name}"') do (
  set "CONTAINER=%%i"
)

if "%IMAGE%"=="" (
  echo [ERR] Nie udalo sie odczytac obrazu z deploymentu %DEPLOYMENT% w namespace %NAMESPACE%.
  exit /b 1
)

echo ==
echo Buduje obraz: %IMAGE%
docker build -t %IMAGE% .
if errorlevel 1 (
  echo [ERR] Docker build nie powiodl sie.
  exit /b 1
)

if /i "%DO_PUSH%"=="push" (
  echo Wysylam obraz do registry: %IMAGE%
  docker push %IMAGE%
  if errorlevel 1 (
    echo [ERR] Docker push nie powiodl sie.
    exit /b 1
  )
)

echo Restartuje rollout deploymentu: %DEPLOYMENT% (ns: %NAMESPACE%)
kubectl rollout restart deploy %DEPLOYMENT% -n %NAMESPACE%
if errorlevel 1 (
  echo [ERR] Rollout restart nie powiodl sie.
  exit /b 1
)

echo Czekam na zakonczenie rollout...
kubectl rollout status deploy %DEPLOYMENT% -n %NAMESPACE%
if errorlevel 1 (
  echo [ERR] Rollout status zakonczyl sie bledem.
  exit /b 1
)

echo ==
echo GOTOWE. Obraz: %IMAGE%
endlocal
