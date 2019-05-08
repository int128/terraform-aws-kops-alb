# OIDC authentication

You can setup OIDC authentication.
This example uses Keycloak and Kubernetes Dashboard Proxy.


## Keycloak

```sh
export keycloak_postgres_host=xxx.xxx.rds.amazonaws.com
```


## Kubernetes Dashboard Proxy

```sh
export oidc_discovery_url=https://accounts.google.com
export oidc_kubernetes_dashboard_client_id=xxx-xxx.apps.googleusercontent.com
export oidc_kubernetes_dashboard_client_secret=xxxxxx
```

See also the tutorial at [int128/kubernetes-dashboard-proxy](https://github.com/int128/kubernetes-dashboard-proxy).
