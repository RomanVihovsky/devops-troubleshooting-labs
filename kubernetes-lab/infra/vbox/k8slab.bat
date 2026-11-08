@echo off
rem k8slab.bat - create and manage the kubernetes-lab node VMs (VirtualBox on Windows).
rem Linux/macOS hosts use k8slab.sh (same commands). Run it from the kit folder made by "./lab vm kit".
rem It only ever touches the VMs listed in nodes.csv (k8s-*); everything inside the VMs is done by ./lab.
setlocal EnableExtensions EnableDelayedExpansion
set "KIT=%~dp0"
set "KIT=%KIT:~0,-1%"
if not defined K8SLAB_HOME set "K8SLAB_HOME=%USERPROFILE%\k8slab"
for %%f in (kit.env nodes.csv seed.iso) do if not exist "%KIT%\%%f" (
  echo ERROR: %%f is missing next to k8slab.bat - copy the whole kit folder made by "./lab vm kit"
  exit /b 1
)
for /f "usebackq eol=# tokens=1,* delims==" %%a in ("%KIT%\kit.env") do set "%%a=%%b"

rem VBoxManage: VBOXMANAGE (full path), else the installer variable, else the default folder; put it on PATH
if defined VBOXMANAGE (
  for %%v in ("%VBOXMANAGE%") do set "VBDIR=%%~dpv"
) else if defined VBOX_MSI_INSTALL_PATH (
  set "VBDIR=%VBOX_MSI_INSTALL_PATH%"
) else (
  set "VBDIR=%ProgramFiles%\Oracle\VirtualBox\"
)
if not exist "%VBDIR%VBoxManage.exe" (
  echo ERROR: VBoxManage.exe not found in "%VBDIR%" - set VBOXMANAGE=C:\path\to\VBoxManage.exe
  exit /b 1
)
set "PATH=%VBDIR%;%PATH%"
set "VDI=%K8SLAB_HOME%\base\%BASE_DISK%"
set "SEED=%K8SLAB_HOME%\base\seed.iso"

if "%~1"=="" (call :usage & pause & exit /b 0)

rem ---- arguments: command [snapshot-name] [nodes...]
set "CMD=%~1"
if "%CMD%"=="" set "CMD=help"
set "SNAP="
set "ARGS="
shift
if /i "%CMD%"=="snapshot" (set "SNAP=%~1" & shift)
if /i "%CMD%"=="restore" (set "SNAP=%~1" & shift)
:collect
if "%~1"=="" goto collected
set "ARGS=%ARGS% %~1"
shift
goto collect
:collected

if /i "%CMD%"=="check"    goto cmd_check
if /i "%CMD%"=="create"   goto cmd_create
if /i "%CMD%"=="start"    goto cmd_start
if /i "%CMD%"=="stop"     goto cmd_stop
if /i "%CMD%"=="status"   goto cmd_status
if /i "%CMD%"=="snapshot" goto cmd_snapshot
if /i "%CMD%"=="restore"  goto cmd_restore
if /i "%CMD%"=="destroy"  goto cmd_destroy
call :usage
if /i "%CMD%"=="help" exit /b 0
exit /b 1

rem =========================================================================== commands
:cmd_check
call :check || exit /b 1
echo OK
exit /b 0

:cmd_create
call :select create || exit /b 1
call :check || exit /b 1
call :ensure_base || exit /b 1
call :foreach create_vm || exit /b 1
echo ==^> booting - first boot takes 1-2 min. Then, on the desktop VM:  ./lab vm wait
exit /b 0

:cmd_start
call :select any || exit /b 1
call :foreach start_vm
exit /b 0

:cmd_stop
call :select any || exit /b 1
call :foreach stop_send
call :foreach stop_wait
exit /b 0

:cmd_status
set "SEL= "
for /f "usebackq eol=# tokens=1 delims=," %%a in ("%KIT%\nodes.csv") do set "SEL=!SEL!%%a "
echo NODE      IP              STATE       ROLE          SNAPSHOT
call :foreach status_vm
exit /b 0

:cmd_snapshot
call :snapname || exit /b 1
call :select any || exit /b 1
call :foreach stop_send
call :foreach stop_wait
call :foreach snap_take || exit /b 1
call :foreach start_vm
exit /b 0

:cmd_restore
call :snapname || exit /b 1
call :select any || exit /b 1
call :foreach snap_check || exit /b 1
call :foreach hard_off
call :foreach stop_wait
call :foreach snap_restore || exit /b 1
call :foreach start_vm
exit /b 0

:cmd_destroy
call :select any || exit /b 1
echo Nodes:%SEL%
set "ANS="
set /p "ANS=Delete these VMs and their disks? [y/N] "
if /i not "%ANS%"=="y" (echo aborted & exit /b 1)
call :foreach hard_off
call :foreach stop_wait
call :foreach destroy_vm
echo The base disk and the image stay in "%K8SLAB_HOME%" - delete that folder to remove everything.
exit /b 0

rem =========================================================================== helpers
:usage
echo k8slab.bat - the kubernetes-lab node VMs (VirtualBox group %VM_GROUP%)
echo   check                     VirtualBox version, host-only network %HOSTONLY_IP%, free disk
echo   create [nodes]            download + verify the Ubuntu image once, create and boot the VMs
echo   start ^| stop [nodes]      start headless / ACPI shutdown (power off after 90 s)
echo   status                    state, IP and current snapshot of every node
echo   snapshot NAME [nodes]     stop, snapshot (replaces one of the same name), start
echo   restore NAME [nodes]      power off, restore the snapshot, start
echo   destroy [nodes]           power off and delete the VMs and their disks (asks first)
echo nodes: names from nodes.csv (k8s-cp1 or just cp1). Default: all except role "spare".
echo Files: %K8SLAB_HOME%  (set K8SLAB_HOME=D:\k8slab to change)
exit /b 0

rem :select create/any - SEL = " name name " from ARGS (default: every row; create skips spares)
:select
set "SEL= "
set "A=%ARGS%"
if "%A%"==" all" set "A="
if not "%A%"=="" goto select_args
for /f "usebackq eol=# tokens=1,7 delims=," %%a in ("%KIT%\nodes.csv") do (
  if /i "%1"=="create" (
    if /i not "%%b"=="spare" set "SEL=!SEL!%%a "
  ) else (
    set "SEL=!SEL!%%a "
  )
)
exit /b 0
:select_args
for %%n in (%A%) do (
  set "N=%%n"
  if /i not "!N:~0,4!"=="k8s-" set "N=k8s-!N!"
  set "FOUND="
  for /f "usebackq eol=# tokens=1 delims=," %%a in ("%KIT%\nodes.csv") do if /i "%%a"=="!N!" set "FOUND=1"
  if not defined FOUND (
    echo ERROR: unknown node: %%n - see nodes.csv
    exit /b 1
  )
  set "SEL=!SEL!!N! "
)
exit /b 0

rem :foreach label - call :label name cpus mem ip mac1 mac2 role for every selected row, in nodes.csv order
:foreach
for /f "usebackq eol=# tokens=1-7 delims=," %%a in ("%KIT%\nodes.csv") do (
  set "T=!SEL: %%a =!"
  if not "!T!"=="!SEL!" (
    call :%~1 %%a %%b %%c %%d %%e %%f %%g
    if errorlevel 1 exit /b 1
  )
)
exit /b 0

:snapname
if "%SNAP%"=="" goto snapname_bad
echo %SNAP%| findstr /r "^[A-Za-z0-9._-]*$" >nul || goto snapname_bad
exit /b 0
:snapname_bad
echo ERROR: usage: k8slab.bat %CMD% NAME [nodes]   (NAME: letters, digits, . _ -)
exit /b 1

rem :state vm - ST = VMState (running, poweroff, ...) or "none"
:state
set "ST=none"
for /f "tokens=2 delims==" %%s in ('VBoxManage.exe showvminfo "%~1" --machinereadable 2^>nul ^| findstr /b "VMState="') do set "ST=%%~s"
exit /b 0

:sleep2
ping -n 3 127.0.0.1 >nul
exit /b 0

:check
for /f "tokens=*" %%v in ('VBoxManage.exe --version') do set "VBVER=%%v"
echo VirtualBox %VBVER%
set "VBMAJ="
set "VBMIN=0"
for /f "tokens=1,2 delims=." %%m in ("%VBVER%") do (set "VBMAJ=%%m" & set "VBMIN=%%n")
if not defined VBMAJ (echo ERROR: "VBoxManage.exe --version" gave no version & exit /b 1)
if %VBMAJ% LSS 7 (echo ERROR: VirtualBox 7.0 or newer is required & exit /b 1)
rem VirtualBox 7.1+ requires the platform architecture on createvm
set "ARCH="
if %VBMAJ% GTR 7 set "ARCH=--platform-architecture x86"
if %VBMAJ% EQU 7 if %VBMIN% GEQ 1 set "ARCH=--platform-architecture x86"
call :find_hostonly
if not defined HOSTONLY (
  echo ERROR: no host-only adapter with IP %HOSTONLY_IP%.
  echo   VirtualBox Manager: File - Tools - Network Manager - Host-only Networks - Create, set 192.168.56.1 / 255.255.255.0
  exit /b 1
)
echo host-only network: %HOSTONLY% ^(%HOSTONLY_IP%^)
if not exist "%K8SLAB_HOME%" mkdir "%K8SLAB_HOME%"
set "FREEGB="
for /f %%g in ('powershell -NoProfile -Command "[int]((Get-Item -LiteralPath $env:K8SLAB_HOME).PSDrive.Free/1GB)"') do set "FREEGB=%%g"
echo free disk at %K8SLAB_HOME%: %FREEGB% GB
if defined FREEGB if %FREEGB% LSS 35 echo WARNING: less than 35 GB free - the 5 VMs need about 25 GB
set "HV="
for /f %%h in ('powershell -NoProfile -Command "(Get-CimInstance Win32_ComputerSystem).HypervisorPresent"') do set "HV=%%h"
if /i "%HV%"=="True" (
  echo WARNING: The Windows hypervisor is running ^(Hyper-V, WSL2, VBS or Memory integrity^).
  echo WARNING: VirtualBox then runs on the slower NEM backend - a green turtle in the VM status bar.
)
exit /b 0

rem :find_hostonly - HOSTONLY = name of the host-only adapter that owns %HOSTONLY_IP%
:find_hostonly
set "HOSTONLY="
set "CUR="
for /f "tokens=1,* delims=:" %%a in ('VBoxManage.exe list hostonlyifs') do (
  set "V="
  for /f "tokens=*" %%v in ("%%b") do set "V=%%v"
  if "%%a"=="Name" set "CUR=!V!"
  if "%%a"=="IPAddress" if "!V!"=="%HOSTONLY_IP%" if not defined HOSTONLY set "HOSTONLY=!CUR!"
)
exit /b 0

:ensure_base
for %%d in (cache base logs) do if not exist "%K8SLAB_HOME%\%%d" mkdir "%K8SLAB_HOME%\%%d"
set "IMG=%K8SLAB_HOME%\cache\%IMAGE_FILE%"
if exist "%VDI%" goto base_type
if exist "%IMG%" goto base_verify
echo ==^> downloading %IMAGE_URL% (~600 MB, once)
curl.exe -fL --retry 3 -C - -o "%IMG%.part" "%IMAGE_URL%" || exit /b 1
move /y "%IMG%.part" "%IMG%" >nul || exit /b 1
:base_verify
set "H="
for /f "skip=1 delims=" %%h in ('certutil -hashfile "%IMG%" SHA256') do if not defined H set "H=%%h"
if not defined H (echo ERROR: could not hash "%IMG%" & exit /b 1)
set "H=%H: =%"
if /i not "%H%"=="%IMAGE_SHA256%" (
  echo ERROR: checksum mismatch for "%IMG%" - got %H% - deleted, run create again
  del "%IMG%"
  exit /b 1
)
echo ==^> image verified; converting to "%VDI%"
VBoxManage.exe clonemedium disk "%IMG%" "%VDI%" --format VDI >nul || exit /b 1
VBoxManage.exe closemedium disk "%IMG%" >nul 2>&1
VBoxManage.exe modifymedium disk "%VDI%" --resize %DISK_MB% >nul || exit /b 1
:base_type
rem A new disk sits in VirtualBox's global media registry, where it can't be made multiattach. Unregister it
rem (the file stays): the first VM's "storageattach --mtype multiattach" re-opens it and sets the type.
VBoxManage.exe showmediuminfo disk "%VDI%" 2>nul | findstr /r /c:"^Type: *multiattach" >nul
if errorlevel 1 VBoxManage.exe closemedium disk "%VDI%" >nul 2>&1
fc /b "%KIT%\seed.iso" "%SEED%" >nul 2>&1
if errorlevel 1 (copy /y "%KIT%\seed.iso" "%SEED%" >nul || echo WARNING: could not update "%SEED%" - is it in use?)
exit /b 0

rem :create_vm name cpus mem ip mac1 mac2 role
:create_vm
VBoxManage.exe showvminfo "%~1" >nul 2>&1
if not errorlevel 1 (echo    %~1: exists, skipped & exit /b 0)
echo ==^> %~1: %~2 vCPU, %~3 MB, %~4
VBoxManage.exe createvm --name "%~1" %ARCH% --ostype Ubuntu_64 --groups "%VM_GROUP%" --register >nul || exit /b 1
VBoxManage.exe modifyvm "%~1" --cpus %~2 --memory %~3 --vram 16 --graphicscontroller vmsvga --firmware bios --ioapic on --rtc-use-utc on --nested-hw-virt off --paravirt-provider default --boot1 disk --boot2 dvd --boot3 none --boot4 none --audio-enabled off --usb-ohci off --usb-ehci off --usb-xhci off --clipboard-mode disabled --drag-and-drop disabled || goto create_fail
VBoxManage.exe modifyvm "%~1" --nic1 nat --nic-type1 82540EM --mac-address1 %~5 --nic2 hostonly --nic-type2 82540EM --host-only-adapter2 "%HOSTONLY%" --mac-address2 %~6 || goto create_fail
VBoxManage.exe modifyvm "%~1" --uart1 0x3F8 4 --uart-mode1 file "%K8SLAB_HOME%\logs\%~1-console.log" || goto create_fail
VBoxManage.exe storagectl "%~1" --name SATA --add sata --controller IntelAhci --portcount 2 --hostiocache on || goto create_fail
VBoxManage.exe storageattach "%~1" --storagectl SATA --port 0 --device 0 --type hdd --medium "%VDI%" --mtype multiattach || goto create_fail
VBoxManage.exe storageattach "%~1" --storagectl SATA --port 1 --device 0 --type dvddrive --medium "%SEED%" || goto create_fail
VBoxManage.exe startvm "%~1" --type headless >nul || goto create_fail
exit /b 0
:create_fail
echo ERROR: creating %~1 failed - removing the half-made VM so "create" can run again
VBoxManage.exe unregistervm "%~1" --delete >nul 2>&1
exit /b 1

:start_vm
call :state %1
if "%ST%"=="none" (echo    %~1: not created & exit /b 0)
if "%ST%"=="running" (echo    %~1: running & exit /b 0)
if "%ST%"=="paused" (VBoxManage.exe controlvm "%~1" resume & exit /b 0)
VBoxManage.exe startvm "%~1" --type headless >nul && echo    %~1: started
exit /b 0

:stop_send
call :state %1
if "%ST%"=="running" VBoxManage.exe controlvm "%~1" acpipowerbutton >nul 2>&1
exit /b 0

:hard_off
call :state %1
if "%ST%"=="running" VBoxManage.exe controlvm "%~1" poweroff >nul 2>&1
if "%ST%"=="paused" VBoxManage.exe controlvm "%~1" poweroff >nul 2>&1
exit /b 0

rem :stop_wait name - wait up to 90 s for power-off, then pull the plug
:stop_wait
set /a TRIES=0
:stop_wait_loop
call :state %1
if "%ST%"=="none" exit /b 0
if "%ST%"=="poweroff" (echo    %~1: poweroff & exit /b 0)
if "%ST%"=="aborted" (echo    %~1: aborted & exit /b 0)
if "%ST%"=="saved" (echo    %~1: saved & exit /b 0)
set /a TRIES+=1
if %TRIES% GEQ 45 (
  echo WARNING: %~1: no ACPI shutdown after 90 s - powering off
  VBoxManage.exe controlvm "%~1" poweroff >nul 2>&1
  call :sleep2
  exit /b 0
)
call :sleep2
goto stop_wait_loop

:status_vm
call :state %1
set "SN=-"
if not "%ST%"=="none" (
  for /f "tokens=2 delims==" %%s in ('VBoxManage.exe snapshot "%~1" list --machinereadable 2^>nul ^| findstr /b "CurrentSnapshotName="') do set "SN=%%~s"
)
if "%ST%"=="none" set "ST=not created"
set "L1=%~1          "
set "L2=%~4                "
set "L3=%ST%            "
set "L4=%~7              "
echo !L1:~0,9! !L2:~0,15! !L3:~0,11! !L4:~0,13! %SN%
exit /b 0

:snap_check
call :state %1
if "%ST%"=="none" exit /b 0
VBoxManage.exe snapshot "%~1" showvminfo "%SNAP%" >nul 2>&1
if errorlevel 1 (echo ERROR: %~1 has no snapshot named %SNAP% & exit /b 1)
exit /b 0

:snap_take
call :state %1
if "%ST%"=="none" exit /b 0
VBoxManage.exe snapshot "%~1" showvminfo "%SNAP%" >nul 2>&1
if not errorlevel 1 VBoxManage.exe snapshot "%~1" delete "%SNAP%" >nul
VBoxManage.exe snapshot "%~1" take "%SNAP%" --description "kubernetes-lab %DATE% %TIME%" >nul || exit /b 1
echo    %~1: snapshot %SNAP% taken
exit /b 0

:snap_restore
call :state %1
if "%ST%"=="none" exit /b 0
VBoxManage.exe snapshot "%~1" restore "%SNAP%" >nul || exit /b 1
echo    %~1: restored %SNAP%
exit /b 0

:destroy_vm
call :state %1
if "%ST%"=="none" exit /b 0
VBoxManage.exe unregistervm "%~1" --delete && echo    %~1: deleted
exit /b 0
