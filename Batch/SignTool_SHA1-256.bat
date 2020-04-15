@ECHO OFF
SET SIGNTOOL="C:\Program Files (x86)\Windows Kits\10\bin\x64\signtool.exe"
%SIGNTOOL% sign /fd sha1 /f "..\Certificati\AndreaMagni.pfx" /p andrea /t http://timestamp.digicert.com "%1"
%SIGNTOOL%  sign /fd sha256 /f "..\Certificati\AndreaMagni.pfx" /p andrea /tr http://timestamp.digicert.com /as "%1"
PAUSE
