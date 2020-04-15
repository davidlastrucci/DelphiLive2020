@ECHO OFF
SET MAKECERT="C:\Program Files (x86)\Windows Kits\10\bin\x64\makecert.exe"
SET PVK2PFX="C:\Program Files (x86)\Windows Kits\10\bin\x64\pvk2pfx.exe"
%MAKECERT% -r -pe -n "CN=Andrea Magni" -ss CA -sr CurrentUser -a sha256 -cy authority -sky signature -sv ..\Certificati\AndreaMagni.pvk ..\Certificati\AndreaMagni.cer
PAUSE
%PVK2PFX% -pvk ..\Certificati\AndreaMagni.pvk -spc ..\Certificati\AndreaMagni.cer -pfx ..\Certificati\AndreaMagni.pfx -po andrea
PAUSE