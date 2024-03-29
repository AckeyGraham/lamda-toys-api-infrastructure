param location string
param prefix string
param vnetId  string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: '${prefix}-la-workspace'
  location: location
  properties: {
    sku: {
      name: 'Standard'
    }
  }
}

resource env 'Microsoft.Web/kubeEnvironments@2022-09-01' = {
  name:'${prefix}-container-env'
location: location
kind: 'containerenvironment'
properties:{
   environmentType: 'managed'
  internalLoadBalancerEnabled: false
  appLogsConfiguration:{
    destination:'log-analytics'
    logAnalyticsConfiguration:{
      customerId: logAnalyticsWorkspace.properties.customerId
      sharedKey: logAnalyticsWorkspace.listkeys().primarySharedKeys
    }
  }
  containerAppsConfiguration:{
    appSubnetResourceId: '${vnetId}/subnets/acaAppSubnet'
    controlPlaneSubnetResourceId: '${vnetId}/subnets/acaControlPlaneSubnet'
  }
}

}

