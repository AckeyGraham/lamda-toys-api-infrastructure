param location string
param prefix string
param ControlPlaneSubnet string
param acaAppSubnet string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: '${prefix}-la-workspace001'
  location: location
  properties: {
    sku: {
      name: 'Standard'
    }
  }
}

resource env 'Microsoft.Web/kubeEnvironments@2023-01-01' = {
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
    appSubnetResourceId: ControlPlaneSubnet
    controlPlaneSubnetResourceId: acaAppSubnet
  }
}

}

