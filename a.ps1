Add-AzureRmAccount 
Select-AzureRmSubscription -SubscriptionName "WTW-RSGNA-NONPROD"

#create OS Disk from Specialized VHD

$sourceUri = 'https://migrationtestrsg1.blob.core.windows.net/vhds/Migrate-VM-Test-osdisk.vhd'
$osDiskName = 'migration_VM_test'
$osDisk = New-AzureRmDisk -DiskName $osDiskName -Disk `
    (New-AzureRmDiskConfig -AccountType PremiumLRS  -Location 'UK South' -CreateOption Import  `
    -SourceUri $sourceUri) `
    -ResourceGroupName After-MigrationRG


#create new VM-Vnet
#--Subnet
$subnetName = 'mySubNet'
$singleSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.0.0/24
#--Vnet
$vnetName = "myVnetName"
$vnet = New-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName Test-Server08-RG -Location 'East US' `
    -AddressPrefix 10.0.0.0/16 -Subnet $singleSubnet

#--NSG
$nsgName = "myNsg"

$rdpRule = New-AzureRmNetworkSecurityRuleConfig -Name myRdpRule -Description "Allow RDP"  `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 110 `
    -SourceAddressPrefix Internet -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange 3389
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName Test-Server08-RG -Location 'East US' `
    -Name $nsgName -SecurityRules $rdpRule

#--Nic

$ipName = "myIP"
$pip = New-AzureRmPublicIpAddress -Name $ipName -ResourceGroupName Test-Server08-RG -Location 'East US' `
   -AllocationMethod Dynamic

$nicName = "myNicName"
$nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName Test-Server08-RG `
    -Location 'East US' -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id

#--VM Config
$vmName = "server200832bit"
$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize "Standard_DS3_V2"

#--Add NIc
$vm = Add-AzureRmVMNetworkInterface -VM $vmConfig -Id $nic.Id


#--Add OS Disk
$vm = Set-AzureRmVMOSDisk -VM $vm -ManagedDiskId $osDisk.Id -StorageAccountType PremiumLRS `
    -DiskSizeInGB 127 -CreateOption Attach -Windows

#Deploy VM
New-AzureRmVM -ResourceGroupName Test-Server08-RG -Location 'East US' -VM $vm