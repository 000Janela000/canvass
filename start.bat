@echo off
echo Starting LeadScout...
echo.
echo Backend:  http://localhost:8000
echo Frontend: http://localhost:3000
echo.
wt -w leadscout new-tab --title "LeadScout - Backend" --suppressApplicationTitle cmd /k "cd /d %~dp0backend && uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload" ; new-tab --title "LeadScout - Frontend" --suppressApplicationTitle cmd /k "cd /d %~dp0frontend && npm run dev"
echo Both servers started in Windows Terminal tabs.
