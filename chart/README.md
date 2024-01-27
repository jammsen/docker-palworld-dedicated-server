# Palworld Helm Chart

This chart installs a Palworld deployment on a [Kubernetes](http://kubernetes.io/) cluster using the [Helm](https://helm.sh/) package manager.

## Install Chart

```sh
helm install [-n NAMESPACE] RELEASE_NAME ./chart
```

## Uninstall Chart

```sh
helm uninstall [-n NAMESPACE] RELEASE_NAME
```

## Upgrading Chart

```sh
helm upgrade [-n NAMESPACE] RELEASE_NAME ./chart
```

## Configuration

See [Customizing the Chart Before Installing](https://helm.sh/docs/intro/using_helm/#customizing-the-chart-before-installing). To see all configurable options with detailed comments, visit the chart's [values.yaml](./values.yaml).

### Networking

This Chart uses a [LoadBalancer Service](https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer) to expose the application outside Kubernetes:

```yaml
service:
  type: LoadBalancer
  ## Example annotations for kube-vip or MetalLB to assign an IP to the LoadBalancer
  annotations: {}
    # kube-vip.io/loadbalancerIPs: 192.168.1.100
    # metallb.universe.tf/loadBalancerIPs: 192.168.1.100
  gamePort: 8211
  queryPort: 27015
  rconPort: 25575
```

Note: Port-Forwarding or NAT may be required for the configured ports.

### Environment variables

To configure the server, add the [environment variables](https://github.com/jammsen/docker-palworld-dedicated-server#environment-variables) to `env`:

```yaml
env:
  TZ: UTC # Change this for logging and backup
  ALWAYS_UPDATE_ON_START: true
  MAX_PLAYERS: 16
  MULTITHREAD_ENABLED: true
  COMMUNITY_SERVER: false
  RCON_ENABLED: true
  SERVER_NAME: "serverNameHere"
  SERVER_DESCRIPTION: ""
  BACKUP_ENABLED: true
  BACKUP_CRON_EXPRESSION: 0 * * * *
  SERVER_PASSWORD: "serverPasswordHere"
  ADMIN_PASSWORD: "adminPasswordHere"
```

Note: This Chart configures the settings for `PUBLIC_IP`, `PUBLIC_PORT`, `QUERY_PORT`, and `RCON_PORT`. The external ports for these services can be set in [Networking](#networking).

### Environment variables from secret

Environment variables can optionally be sourced from an existing [secret](https://kubernetes.io/docs/concepts/configuration/secret/) using `envFrom`:

```yaml
envFrom:
  SERVER_PASSWORD:
    secretKeyRef:
      name: palworld-config
      key: serverPassword
  ADMIN_PASSWORD:
    secretKeyRef:
      name: palworld-config
      key: adminPassword
```
