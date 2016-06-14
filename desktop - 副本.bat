set subl="C:\Program Files (x86)\Sublime Text 3\subl.exe"
set proj="C:\projects\jasygl"
set mydir="C:\Users\xn\Desktop"
set gitbash="C:\Program Files\Git\git-bash.exe"
%gitbash% %proj% --login -i
%gitbash% "C:\cloud" --login -i
%subl% %proj%
%subl% "C:\cloud"
start "" %proj%
start "" "C:\cloud"
cd %mydir%
start "" %mydir%"\word"
start "" %mydir%"\docProps"
start "" %mydir%"\_rels"
start "" %mydir%"\http1.1"
start "" %mydir%"\master.html"
rem start http://127.0.0.1:8000
rem cd %proj%
rem %subl% %proj%
rem cmd /k python "%proj%\manage.py" runserver
