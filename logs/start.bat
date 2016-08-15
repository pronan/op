set subl="C:\Program Files (x86)\Sublime Text 3\subl.exe"
set git-bash="C:\Program Files\Git\git-bash.exe"
rem for %%x in ("C:\projects\jarsj","C:\projects\jasygl","C:\projects\wdksw","c:\cloud") do (
rem    cd %%x
rem    start "" .
rem    %subl% .
rem )
for %%x in ("C:\projects\jarsj","C:\projects\jasygl","C:\projects\wdksw","c:\cloud") do (
   cd %%x
   git pull
)
pause
