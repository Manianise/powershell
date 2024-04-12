<#Creation d'une VM (Master)#>

<#activation du Hyper-V sur le machine en cas de deja installe#>
enabled-WindowsOptionalFeature -Online -FeatureName Microsoft-hyper-v-all
New-VMSwitch -name Externe -NetAdapterName WI-FI

<#Creation de une nouvelle machine virtuelle#>
New-VM -Name Master -SwitchName Interne -Path c:\hyperv\ -NewVHDPath c:\hyper-v\Master\Master.vhdx -NewVHDSizeBytes 200GB -MemoryStartupBytes 4GB -Generation 2

<#activer ou desactiver les ponits de controle - snapshot#>
Enable-VMIntegrationService -VMName Master -Name Interface*
Set-VM -Name Master -CheckpointType Disabled

<#add ou remove Processeur sur les machines#>
Set-VM -Name Master -ProcessorCount 2

<#mount drive dvd disque sur le machine#>
Add-VMDvdDrive -VMName Master -Path C:\ISO\fr-fr_windows_server_2022_x64_dvd_9f7d1adb.iso

$vmdvd = Get-VMDvdDrive -VMName Master

<#changer la ordre de boot - en cas par disque dvd#>
Set-VMFirmware -VMName Master -FirstBootDevice $vmdvd

<#activer service d'invite#>
Enable-VMIntegrationService -VMName "Master" -Name Interface*

<#Verifier les switches existantes#>
Get-NetAdapter

<#Renomer Computer#>
Rename-Computer HOTE-03

<#changer le nom  d'user #>
Rename-LocalUser -Name Administrateur -NewName admin

<#changer le nome de carte reseau#>
Get-NetAdapter -Name Ethernet | Rename-NetAdapter -NewName Interne
Rename-NetAdapter -name ethernet -NewName Interne

<#changer le IP#>
New-NetIPAddress -InterfaceIndex 4 -IPAddress 10.144.0.30  -PrefixLength 24 -DefaultGateway 10.144.0.1

<#Add DNS#>
Set-DnsClientServerAddress -InterfaceIndex 6 -ServerAddresses 10.144.0.1


<#creation des switchs#>
New-VMSwitch -name MPIO1 -SwitchType Private
New-VMSwitch -name MPIO2 -SwitchType Private
New-VMSwitch -name Pulsation -SwitchType Private   
New-VMSwitch -name Interne -SwitchType Internal
New-VMSwitch -name Externe -NetAdapterName WI-FI

<#Format la machine#><#ATT: 
ne pas aplliquer sysprep sur le machine physique - tres grave perdu de machine 
cocher lectture seule en disque#>
C:\windows\system32\sysprep\sysprep.exe /generalize /oobe /shutdown


<#Creation des disques avec diferenciation#>
New-VHD -Path C:\HyperV\DC-01\DC-01.vhdx -ParentPath c:\HyperV\Master\Master.vhdx -Differencing
New-VHD -Path C:\HyperV\Hote-01\Hote-01.vhdx -ParentPath c:\HyperV\Master\Master.vhdx -Differencing
New-VHD -Path C:\HyperV\Hote-02\Hote-02.vhdx -ParentPath c:\HyperV\Master\Master.vhdx -Differencing
New-VHD -Path C:\HyperV\Hote-03\Hote-03.vhdx -ParentPath c:\HyperV\Master\Master.vhdx -Differencing

<#Creation des hotes#>
New-VM -Name Hote-03 -MemoryStartupBytes 2GB -Path c:\HyperV\Hote-03 -VHDPath C:\HyperV\Hote-03\Hote-03.vhdx -Generation 2 -SwitchName interne
 New-VM -Name Hote-02 -MemoryStartupBytes 2GB -Path c:\HyperV\Hote-02 -VHDPath C:\HyperV\Hote-02\Hote-02.vhdx -Generation 2 -SwitchName interne
 New-VM -Name Hote-01 -MemoryStartupBytes 2GB -Path c:\HyperV\Hote-01 -VHDPath C:\HyperV\Hote-01\Hote-01.vhdx -Generation 2 -SwitchName interne
 New-VM -Name DC-01 -MemoryStartupBytes 2GB -Path c:\HyperV\DC-01 -VHDPath C:\HyperV\DC-01\DC-01.vhdx -Generation 2 -SwitchName interne
 Enable-VMIntegrationService -VMName DC-01, Hote-01, hote-02, hote-03 -Name Interface*
 Set-VM -Name DC-01, Hote-01, hote-02, hote-03 -ProcessorCount 2
 Set-VM -Name DC-01, Hote-01, hote-02, hote-03 -CheckpointType Disabled


<#Renomer Computer#>
Rename-Computer HOTE-03



<#changer le nome de carte reseau#>
Get-NetAdapter -Name Ethernet | Rename-NetAdapter -NewName Interne
Rename-NetAdapter -name ethernet -NewName Interne

<#changer le IP#>
New-NetIPAddress -InterfaceIndex 4 -IPAddress 10.144.0.30  -PrefixLength 24 -DefaultGateway 10.144.0.1

<#Add DNS#>
Set-DnsClientServerAddress -InterfaceIndex 6 -ServerAddresses 10.144.0.1

#Ajouter au domaine#>
Add-Computer -DomainName form-it.lab -Credential admin@form-it.lab -Restart

<#Installer ADDS#>
Install-WindowsFeature -name AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools

<#Promouvoir le serveur en controlleur de domaine#>
Install-ADDSForest -DomainName form-it.lab -InstallDns:$true 

<#Installer DHCP#>
 Install-WindowsFeature DHCP -IncludeAllSubFeature -IncludeManagementTools

<#Configurer Zone de recherche inversee#>
 Add-DnsServerPrimaryZone -ComputerName DC-01 -NetworkId "10.144.0.1/24" -DynamicUpdate Secure -ReplicationScope Domain

<#Configurer le pointer#>
Add-DnsServerResourceRecordPtr -Name "0.1" -PtrDomainName "DC-01.form-it.lab" -ZoneName "144.10.in-addr.arpa" -ComputerName DC-01


<#Creer OUs#>
New-ADOrganizationalUnit -Name Direction -Path "dc=form-it,dc=lab"
New-ADOrganizationalUnit -Name RH -Path "dc=form-it,dc=lab"
New-ADOrganizationalUnit -Name IT -Path "dc=form-it,dc=lab"
New-ADOrganizationalUnit -Name Vente -Path "dc=form-it,dc=lab"


<#Creer Group#>
New-ADGroup -Name Vendeurs -Path "OU=Vente,DC=form-it,DC=lab" -GroupCategory Security -GroupScope Global
New-ADGroup -Name Directeurs -Path "OU=Direction,DC=form-it,DC=lab" -GroupCategory Security -GroupScope Global
New-ADGroup -Name Recruteurs -Path "OU=RH,DC=form-it,DC=lab" -GroupCategory Security -GroupScope Global
New-ADGroup -Name Techniciens -Path "OU=IT,DC=form-it,DC=lab" -GroupCategory Security -GroupScope Global
New-ADGroup -Name Ingenieurs -Path "OU=IT,DC=form-it,DC=lab" -GroupCategory Security -GroupScope Global

<#Creer Utilisateurs#>
New-ADUser -Name  "Eric Forest" -SamAccountName "forest" -Path "OU=Direction,DC=form-it,DC=lab"
New-ADUser -Name  "Richard Vachon" -SamAccountName "rvachon" -Path "OU=Direction,DC=form-it,DC=lab"
New-ADUser -Name  "Pierre Artaud" -SamAccountName "partaud" -Path "OU=IT,DC=form-it,DC=lab"
New-ADUser -Name  "Julien Garnier" -SamAccountName "jgarnier" -Path "OU=IT,DC=form-it,DC=lab"
New-ADUser -Name  "Gustave Lanois" -SamAccountName "glanois" -Path "OU=Ingenieurs,DC=form-it,DC=lab"
New-ADUser -Name  "Chris Marquis" -SamAccountName "cmarquis" -Path "OU=Ingenieurs,DC=form-it,DC=lab"
New-ADUser -Name  "Mathilde Carnot" -SamAccountName "mcarnot" -Path "OU=RH,DC=form-it,DC=lab"
New-ADUser -Name  "Kevin Marot" -SamAccountName "kmarot" -Path "OU=RH,DC=form-it,DC=lab"
New-ADUser -Name  "Clément Meunier" -SamAccountName "cmeunier" -Path "OU=Vente,DC=form-it,DC=lab"
New-ADUser -Name  "Anne Billot" -SamAccountName "abillot" -Path "OU=Vente,DC=form-it,DC=lab"

Set-ADAccountPassword -Identity forest
Set-ADAccountPassword -Identity rvachon
Set-ADAccountPassword -Identity partaud
Set-ADAccountPassword -Identity jgarnier
Set-ADAccountPassword -Identity glanois
Set-ADAccountPassword -Identity cmarquis
Set-ADAccountPassword -Identity mcarnot
Set-ADAccountPassword -Identity kmarot
Set-ADAccountPassword -Identity cmeunier
Set-ADAccountPassword -Identity abillot
<##>
<#Ajouter user sur le group#>
Add-ADGroupMember -Identity Directeurs -Members "forest", "rvachon"
Add-ADGroupMember -Identity Techniciens -Members "partaud", "jgarnier"
Add-ADGroupMember -Identity Ingenieurs -Members "glanois", "cmarquis"
Add-ADGroupMember -Identity Recruteurs -Members "mcarnot", "kmarot"
Add-ADGroupMember -Identity Vendeurs -Members "cmeunier", "abillot"

<#Ajouter carte reseau virtuel a vm#>
Add-VMNetworkAdapter -VMName Hote-01, Hote-02, Hote-03 -SwitchName MPIO1 
Add-VMNetworkAdapter -VMName Hote-01, Hote-02, Hote-03 -SwitchName MPIO2 -Name MPIO2
Add-VMNetworkAdapter -VMName Hote-01, Hote-02 -SwitchName Pulsation -Name Pulsation
Add-VMNetworkAdapter -VMName DC-01, Hote-01, Hote-02, Hote-03 -SwitchName Externe -Name Externe

Rename-NetAdapter -name "ethernet 5" -NewName Interne | Set-DnsClientServerAddress -InterfaceAlias Interne -ServerAddresses 10.144.0.1
Rename-NetAdapter -name "ethernet 5" -NewName MPIO1 | Set-DnsClientServerAddress -InterfaceAlias MPIO1 -ServerAddresses 10.144.0.1
Rename-NetAdapter -name "ethernet 6" -NewName MPIO2 | Set-DnsClientServerAddress -InterfaceAlias MPIO2 -ServerAddresses 10.144.0.1
Rename-NetAdapter -name "ethernet 6" -NewName Pulsation | Set-DnsClientServerAddress -InterfaceAlias Pulsation -ServerAddresses 10.144.0.1


<#Hote01#>Set-NetIPAddress -InterfaceAlias Interne -IPAddress 10.144.0.10  -PrefixLength 24 |Set-NetIPAddress -InterfaceAlias MPIO1 -IPAddress 10.144.1.10  -PrefixLength 24 | Set-NetIPAddress -InterfaceAlias MPIO2 -IPAddress 10.144.2.10  -PrefixLength 24 | Set-NetIPAddress -InterfaceAlias Pulsation -IPAddress 10.144.3.10  -PrefixLength 24
<#Hote02#>Set-NetIPAddress -InterfaceAlias Interne -IPAddress 10.144.0.20  -PrefixLength 24 |Set-NetIPAddress -InterfaceAlias MPIO1 -IPAddress 10.144.1.20  -PrefixLength 24 | Set-NetIPAddress -InterfaceAlias MPIO2 -IPAddress 10.144.2.20  -PrefixLength 24 | Set-NetIPAddress -InterfaceAlias Pulsation -IPAddress 10.144.3.20  -PrefixLength 24
<#Hote03#>Set-NetIPAddress -InterfaceAlias Interne -IPAddress 10.144.0.30  -PrefixLength 24 |Set-NetIPAddress -InterfaceAlias MPIO1 -IPAddress 10.144.1.30  -PrefixLength 24 | Set-NetIPAddress -InterfaceAlias MPIO2 -IPAddress 10.144.2.30  -PrefixLength 24 


<#Ajouter nouveau disque dinamique hote-03#>
New-VHD -Path  C:\HyperV\Hote-03\DD1.vhdx -SizeBytes 4TB -Dynamic
New-VHD -Path  C:\HyperV\Hote-03\DD2.vhdx -SizeBytes 4TB -Dynamic
New-VHD -Path  C:\HyperV\Hote-03\DD3.vhdx -SizeBytes 4TB -Dynamic
New-VHD -Path  C:\HyperV\Hote-03\DD4.vhdx -SizeBytes 4TB -Dynamic
New-VHD -Path  C:\HyperV\Hote-03\DD5.vhdx -SizeBytes 4TB -Dynamic
New-VHD -Path  C:\HyperV\Hote-03\DD6.vhdx -SizeBytes 4TB -Dynamic
New-VHD -Path  C:\HyperV\Hote-03\DD7.vhdx -SizeBytes 4TB -Dynamic
New-VHD -Path  C:\HyperV\Hote-03\DD8.vhdx -SizeBytes 4TB -Dynamic
New-VHD -Path  C:\HyperV\Hote-03\DD9.vhdx -SizeBytes 4TB -Dynamic

<#Conecter a vm#>
Add-VMHardDiskDrive -VMName Hote-03 -Path C:\HyperV\Hote-03\DD1.vhdx -ControllerType SCSI
Add-VMHardDiskDrive -VMName Hote-03 -Path C:\HyperV\Hote-03\DD2.vhdx -ControllerType SCSI
Add-VMHardDiskDrive -VMName Hote-03 -Path C:\HyperV\Hote-03\DD3.vhdx -ControllerType SCSI
Add-VMHardDiskDrive -VMName Hote-03 -Path C:\HyperV\Hote-03\DD4.vhdx -ControllerType SCSI
Add-VMHardDiskDrive -VMName Hote-03 -Path C:\HyperV\Hote-03\DD5.vhdx -ControllerType SCSI
Add-VMHardDiskDrive -VMName Hote-03 -Path C:\HyperV\Hote-03\DD6.vhdx -ControllerType SCSI
Add-VMHardDiskDrive -VMName Hote-03 -Path C:\HyperV\Hote-03\DD7.vhdx -ControllerType SCSI
Add-VMHardDiskDrive -VMName Hote-03 -Path C:\HyperV\Hote-03\DD8.vhdx -ControllerType SCSI
Add-VMHardDiskDrive -VMName Hote-03 -Path C:\HyperV\Hote-03\DD9.vhdx -ControllerType SCSI

<#creer Pool de Stockage#>
$physicaldisk = Get-PhysicalDisk -canpool $true
New-StoragePool -FriendlyName "StoragePool01" -StorageSubSystemFriendlyName "windows storage*" -PhysicalDisks $physicaldisk

<#creer disque virtuel - RAID#>
New-VirtualDisk -FriendlyName DiskVirtuel-01 -StoragePoolFriendlyName StoragePool01 -ProvisioningType Thin -Size 128TB -ResiliencySettingName Mirror -NumberOfDataCopies 3

<#Initializer disque#>
Get-Disk -Number 10 | Initialize-Disk -PassThru | New-Partition -DriveLetter E -Size 64TB | Format-Volume -FileSystem ReFS

<#Installer Serveur ISCSI #>
Install-WindowsFeature iscsitarget-vss-vds, fs-iscsitarget-server -IncludeAllSubFeature -IncludeManagementTools

<#Creer disque iscsi#>
New-IscsiVirtualDisk -Path 'd:\Iscsivirtualdisk\Disk1.vhdx' -Size 15TB
New-IscsiVirtualDisk -Path 'd:\Iscsivirtualdisk\Disk2.vhdx' -Size 15TB
New-IscsiVirtualDisk -Path 'd:\Iscsivirtualdisk\Disk3.vhdx' -Size 15TB
New-IscsiVirtualDisk -Path 'd:\Iscsivirtualdisk\Disk4.vhdx' -Size 100GB

<#ajuter conection a vm#>
New-IscsiServerTarget -TargetName target-01 -InitiatorIds 'iqn:iqn.1995-05.com.microsoft:hote-01.form-it.lab, iqn:iqn.1995-05.com.microsoft:hote-02.form-it.lab'

<#mappe a la vm#>
Add-IscsiVirtualDiskTargetMapping -TargetName target-01 -Path 'd:\Iscsivirtualdisk\Disk1.vhdx'
Add-IscsiVirtualDiskTargetMapping -TargetName target-01 -Path 'd:\Iscsivirtualdisk\Disk2.vhdx'
Add-IscsiVirtualDiskTargetMapping -TargetName target-01 -Path 'd:\Iscsivirtualdisk\Disk3.vhdx'
Add-IscsiVirtualDiskTargetMapping -TargetName target-01 -Path 'd:\Iscsivirtualdisk\Disk4.vhdx'



