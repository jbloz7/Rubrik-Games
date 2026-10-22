# Rubrik Games

A small Caddy deployment that is the single front door for a set of Kubernetes demo apps: one public LoadBalancer IP, a "Rubrik Games" menu page, hostname-based routing to each app, and automatic Let's Encrypt HTTPS (no ingress controller or cert-manager needed).

The apps it fronts are separate repos:

- [Rubrik-Invaders](https://github.com/jbloz7/Rubrik-Invaders), a space-invaders-style game
- [Rubrik-Chase](https://github.com/jbloz7/Rubrik-Chase), an original maze-chase game

Add another app by adding an entry to the `apps` list in your values file.

## Install

1. Give each app an internal Service (`service.type: ClusterIP`).
2. Create DNS A records, or one wildcard record, for the menu host and every app host, all pointing at the gateway's IP.
3. Copy `examples/values-games-gateway.yaml` to `my-games-values.yaml` (git ignores it), put in your hostnames, and install:

```bash
helm upgrade --install rubrik-games ./chart -n rubrik-games --create-namespace -f my-games-values.yaml
kubectl get svc rubrik-games -n rubrik-games -w          # EXTERNAL-IP is the address your DNS records should use
kubectl logs deploy/rubrik-games -n rubrik-games -f      # watch certificates being issued
```

Check the chart renders first: `helm lint ./chart` and `helm template rubrik-games ./chart -n rubrik-games -f my-games-values.yaml`.

## HTTPS

With `tls.enabled: true` the gateway is HTTPS only: Caddy redirects every `http://` request to `https://` (port 80 stays open for that redirect and for certificate issuance). Set `tls.staging: true` while testing to avoid Let's Encrypt rate limits, then `false`. Set `tls.hsts: true` once real certificates work, to also tell browsers never to try plain HTTP.

With `tls.enabled: false` (the default) the gateway serves plain HTTP, and any unknown host, including the raw IP, shows the menu. `examples/games-menu-preview.html` is a rendered copy of the default menu page.

Certificates are kept in a PVC, so they survive restarts but are re-issued if you delete the namespace.

## The menu

The header shows a logo if you place one at `chart/files/rubrik-logo.svg` (white wordmark, since the page is dark; git ignores the file). Below the cards, a "Recent players" panel lists the latest games from every app that has a `recentPath`. The gateway proxies each app's `recentPath` (a JSON list of `{name, score, level, ts}`, newest first) to the menu page. An app without one is left out of the panel. Card icons come from `chart/files/icon-<id>.png` when `icon: image`.

An app you cannot edit can be shown inside a thin "Back to menu" bar with `frame: true` and a second hostname, `rawHost`. The app must allow being framed.

## Static IP on AKS

Create a Standard SKU static public IP in the cluster's node resource group, so the cluster identity already has rights on it:

```bash
az network public-ip create -g <node-resource-group> -n rubrik-k8s-games-pip --sku Standard --allocation-method Static
az network public-ip show -g <node-resource-group> -n rubrik-k8s-games-pip --query ipAddress -o tsv
```

Set `service.annotations."service.beta.kubernetes.io/azure-pip-name"` to that name in your local values file.

## Moving an existing app behind the gateway

Change its Service to ClusterIP and, if it had a static IP annotation, remove it:

```bash
kubectl patch svc <app> -n <namespace> -p '{"spec":{"type":"ClusterIP"}}'
kubectl annotate svc <app> -n <namespace> service.beta.kubernetes.io/azure-pip-name-
```

If you back the app up with Rubrik, take a new backup afterwards. Older snapshots contain the old LoadBalancer Service, and restoring one would try to claim the IP the gateway now uses.

## Protecting it with Rubrik

Add the `rubrik-games` namespace to a Kubernetes protection set if you want the certificates PVC protected.

Created by James Blower.
