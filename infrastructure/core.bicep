param location string
param prefix string
param vnetSettings object = {
  addressPrefixes: [
    '10.0.0.0/19'
  ]
  subnets: [
    { 
      name: 'subnet1'
      addressPrefix: '10.0.0.0/21'
    }

    { 
      name: 'acaAppSubnet'
      addressPrefix: '10.0.8.0/21'
    }

    { 
      name: 'acaControlPlaneSubnet'
      addressPrefix: '10.0.16.0/21'
    }
  ]
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: '${prefix}-default-nsg'
  location: location
  properties: {
    securityRules: [     
    ]
  }
}


resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: '${prefix}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: vnetSettings.addressPrefixes
    }
    subnets: [ for subnet in vnetSettings.subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressprefix
        networkSecurityGroup: {
            id: networkSecurityGroup.id
        }
    }
    }]
  }
}


resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2021-03-15' = {
  name: '${prefix}-cosmosaccount'
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
      }
    locations: [
      {
        locationName: location
        failoverPriority: 0
      }
    ]
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: false
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
  }
}

resource sqlDb 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-06-15' = {
  name: '${prefix}-sqldb'
  parent: cosmosDbAccount
  properties: {
    resource: {
      id: '${prefix}-sqldb'
    }
    options: {
      
    }
  }
}

resource sqlContainerName 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2021-06-15' = {
  parent: sqlDb 
  name: '${prefix}-orders'
  properties: {
    resource: {
      id: '${prefix}-orders'
      partitionKey: {
        paths: [
          '/id'
        ]
        kind: 'Hash'
      }      
    }
    options: {}
  }
}

resource cosmosPrivateDNS 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.documents.azure.com' 
  location: 'global'
}

resource privateDnsNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${prefix}-dns-link'
  location: 'global'
  parent: cosmosPrivateDNS
  properties:{
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
}

resource cosmosPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-08-01'  = {
  name: '${prefix}-cosmos-pe'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${prefix}-cosmos-pe'
        properties: {
          privateLinkServiceId: cosmosDbAccount.id
          groupIds: ['SQL']
        }
      }
    ]
    subnet: {
      
      id: virtualNetwork.properties.subnets[0].id
    }
  
  }
}

resource cosmosPrivateEndpointDnsLink 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  name:'${prefix}-cosmos-pe-dns'
  parent: cosmosPrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink.documents.azure.com'  
        properties: {
          privateDnsZoneId: cosmosPrivateDNS.id
        }
      }
    ]
  }
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: 'ajgacr1000'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: '${prefix}-kv01'
  location: location
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    enableRbacAuthorization: true
    tenantId: tenant().tenantId
    
    sku: {
      name: 'standard'
      family: 'A'
    }
  }
}

resource keyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'acrAdminPassword'
  properties: {
    value: containerRegistry.listCredentials().passwords[0].value
  }
}

