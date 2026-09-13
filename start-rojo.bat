@echo off
cd /d "%~dp0"

if not exist rojo.exe (
    echo rojo.exe est introuvable dans ce dossier.
    echo Telecharge-le depuis https://github.com/rojo-rbx/rojo/releases
    echo et place le fichier rojo.exe ici, a cote de default.project.json.
    pause
    exit /b 1
)

echo Lancement du serveur Rojo...
echo Laisse cette fenetre ouverte pendant que tu travailles dans Roblox Studio.
echo.
rojo.exe serve

pause
