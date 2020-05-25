$rgName=$args[0]
$containerRegistryName=$args[1]

New-AzContainerRegistry -ResourceGroupName $rgName -Name $containerRegistryName -EnableAdminUser -Sku Basic