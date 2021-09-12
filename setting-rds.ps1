New-ItemProperty `
-Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' `
-Name 'LicensingMode' `
-Value 4 `
-PropertyType 'DWord'

New-ItemProperty `
-Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' `
-Name 'LicenseServers' `
-Value 'localhost' `
-PropertyType 'String'
