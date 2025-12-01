# Setup for winrm

open up powershell and type:
Get-NetConnectionProfile

you will see your wifi name
it will say something like:
Name                (your wifi name)

check if NetworkCategory: Public is there
if it says private then you are good and skip to "winrm config enabling"
if it is public then follow these steps

type:
Set-NetConnectionProfile -InterfaceAlias "yourwifinamehere" -NetworkCategory Private

after you do that confirm it changed by typing:
Get-NetConnectionProfile

if NetworkCategory says private then you are good and go to "winrm config enabling"

# winrm config enabling
winrm quickconfig

this is kinda risky and insecure and it makes your local network unencrypted
winrm set winrm/config/service/auth @{Basic="true"}
winrm set winrm/config/service @{AllowUnencrypted="true"}

this allows you to use winrm in some cases

if it says "make these changes? Y/N" press y then hit enter then after that type:
Enable-PSRemoting -Force
it takes some time but then close powershell and open up the exe and it should run

# important notes

if you are testing this on the same computer ONLY TYPE "localhost" NEVER YOUR IP or it will crash and not work
