$rgName=$args[0]
$containerRegistryName=$args[1]

az acr create --resource-group $rgName --name $containerRegistryName --sku Basic --admin-enabled true