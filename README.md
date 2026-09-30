# Homelab Identity & Infrastructure Platform

I've always hosted game servers for my friends, but the maintenance and constant changes, deployment issues, versioning, and general access has always bothered me. What started as a small project to authenticate users before joining turned into a large project and a test of my knowledge of cloud infrastructure.

I've essentially made a self-hosted homelab built to mirror enterprise cloud infrastructure patterns: centralized identity (SSO/OIDC), a reverse proxy with automated TLS, a VPN control plane with group-based network access, and infrastructure managed as code. I've rebuilt this in stages into a platform for practicing IAM, Docker, Kubernetes, and general Cloud Administration.

## An Aside

While this was primarily a hobby project, it was also built as a hands-on complement to my production support work in cloud infrastructure (Cloud IAM, cloud administration, OCI IAM), and is aimed at demonstrating my ability to administer infrastructure-as-code and hands-on cloud infra in general. It also serves as a public, documented proof of building (not just troubleshooting) cloud systems. Every design decision below is deliberately the same shape as how an enterprise would do it, just at home scale.

## Architecture

```
                         Internet
                            │
                     Cloudflare DNS
                            │
                    ┌───────▼────────┐
                    │     Traefik    │  reverse proxy, TLS via
                    │(reverse proxy) │  Let's Encrypt DNS-01 challenge
                    └───────┬────────┘
                            │  (Internal Docker network)
          ┌─────────────────┼─────────────────┐
          │                 │                 │
   ┌──────▼──────┐   ┌──────▼──────┐   ┌──────▼──────┐
   │  Keycloak   │   │   Grafana   │   │  Headscale  │
   │  (OIDC IdP) │◄──┤  (OIDC RP)  │   │ (VPN control│
   │ + Postgres  │   └─────────────┘   │    plane)   │
   └─────────────┘                     └────── ┬─────┘
                                               │
                                        Tailscale clients
                                     (friends' devices, auth
                                      via Keycloak login)
                                               │
                                    ┌──────────▼──────────┐
                                    │  Raspberry Pi        │
                                    │  (subnet router)     │
                                    └──────────┬──────────┘
                                               │
                                   ┌───────────▼───────────┐
                                   │  gameservers subnet    │
                                   │  (10.10.10.0/24,       │
                                   │   dedicated Docker     │
                                   │   bridge network)      │
                                   │  - Minecraft, etc.      │
                                   └────────────────────────┘
```

**Identity Access** Every application (Grafana, Headscale) trusts Keycloak rather than managing its own users. Group membership in Keycloak (`admins`, `players`) is carried as a claim into each application's own token and mapped to that app's native permission model — a Grafana role on one side, network-level ACL access on the other.

## Services

| Service | Role | Notes |
|---|---|---|
| Traefik | Reverse proxy, TLS termination | Docker-label-based service discovery; `exposedByDefault: false` so nothing is reachable unless explicitly labeled |
| Keycloak + Postgres | Central identity provider (OIDC) | Realm-based; `homelab` realm holds all application clients, `master` reserved for administering Keycloak itself |
| Grafana | Monitoring dashboard, first OIDC client | Group-to-role mapping via JMESPath (`admins` → Grafana Admin, `players` → Viewer) |
| Headscale | Self-hosted Tailscale control plane | OIDC login required to register a device; group claims will drive ACL-based network access |
| Game servers (Minecraft, etc.) | Containerized workloads | Isolated on a dedicated `10.10.10.0/24` Docker bridge network, reachable only via the VPN |
| Raspberry Pi | Headscale subnet router | Advertises the game-server subnet into the tailnet; hardlined to the router |
| restic | Automated backups | Nightly, encrypted, deduplicated; local + (planned) offsite to cloud |

## Design principles carried through the project

- **Deny by default, allow explicitly.** Traefik doesn't expose a container unless labeled. UFW's default routed policy is deny, with narrow allow rules added only for the specific subnet pair that needs it. Docker's own per-bridge forwarding rules follow the same pattern.
- **Identity as the access-control boundary.** Keycloak group membership is the single source of truth for identity assurance, translated into each system's native mechanism (app role, VPN ACL) rather than duplicated by hand in multiple places.
- **Config and secrets never share a home.** Compose files are tracked in git; `.env` files (and anything under `./data`) are gitignored and documented instead via `.env.example`.
- **Everything is planned to be reproducible from the repo.** A fresh clone plus documented manual steps (moving toward Terraform for the identity layer) should be able to rebuild the whole stack from nothing.

## Troubleshooting log

Kept here deliberately, since the debugging process is as representative of the skill as the finished config.

### Docker Compose
Mint's default `docker.io` apt package doesn't ship the Compose plugin. Fixed by installing Docker from Docker's official apt repository manually. Docker compose also doesn't seem to recognize docker containernames while not in the parent directory. Still working on that...

### Container UID/permission mismatches
Different official images run as different non-root UIDs (Grafana: `472`, `Minecraft`: `1000`, Postgres/Keycloak is different depending on the version). Bind-mounted data directories have to be permission managed to match, or the container fails to write on first start. Now tracked in a table so this doesn't have to be re-derived per service.

### Routed traffic silently dropped between the Pi and the game-server subnet
ICMP requests visible arriving on the host, no replies were sent. Root-caused by tracing packet counters through the full path with `iptables -Z <chain>` (zero counters) before and after a test ping, chain by chain, rather than reading rules by eye:

1. `DOCKER-USER` — matched nothing (not the blocker; a common false lead, since a rule showing zero hits here just means traffic never matched it, not that it was denied here)
2. `FORWARD` — UFW's default `deny (routed)` policy was the actual first drop point
3. After scoping `ufw route allow` rules to the specific subnet pair, traffic passed `FORWARD` but still didn't reach the container
4. `DOCKER-BRIDGE` / `DOCKER-FORWARD` — Docker maintains its own explicit per-bridge-interface ACCEPT list in `DOCKER-FORWARD`; a manually created bridge network isn't added to this list automatically the way networks tied to existing services were. Fixed with a targeted `iptables -I DOCKER-FORWARD -o <bridge-interface> -j ACCEPT`, persisted via a systemd oneshot unit that reapplies after `docker.service` starts (since Docker regenerates this chain on daemon restart)

### Headscale OIDC: empty callback parameters
`error='empty OIDC callback params'` on the OIDC callback url. Found out the issue was Keycloak rejecting the request and returning an empty callback.

### Headscale OIDC: `invalid_scope`
Found this out eventually by digging through browser tools. Request to authenticate with Headscale was being redirected correctly to Keycloak auth url, but hit 400 on the way back: Keycloak rejected the auth request with `invalid_scope: openid profile email groups`. Headscale requests a `groups` scope by default (needed for `allowed_groups` group-based access control), but the client-scope mapper I set up for Grafana didn't automatically extend to a second application requesting the same claim name. Each OIDC client needs the `groups` scope explicitly assigned under its Client Scopes tab; a scope built as a dedicated mapper on one client isn't reusable by another without being added as a realm-level, shared client scope.

### Subnet Router Firewall:
This one took the longest time to figure out. I was having problems with my Raspberry Pi reaching to the docker network container holding all my game services. I could see the packets coming in from tcpdump, but they weren't getting redirected to the bridge network interface for the docker container. I kept messing with firewall rules and got really deep into the iptables chaining rules for a while, before finding an obscure networking forum post that mentioned that iptables has a PREROUTING table that evaluates rules before the general iptable rules even fire. Lo and behold, the raw table had DROP rules for every bridge network interface I had on my machine. 

## Planned next steps

- [ ] Troubleshoot Tailscale issues with Game Server host recognition 
- [ ] Have to make an easy, user friendly installation guide for Tailscale and Keycloak logins since my friends aren't all tech savvy.
- [ ] I want to figure out the Headscale ACL policy mapping Keycloak groups (`admins`, `players`) to the subnet.
- [ ] Learn Terraform to manage Keycloak realm/clients/groups/mappers 
- [ ] I need to get another disk to run the server off of, right now the whole thing is running on an external usb hard drive -_-
- [ ] Docker socket proxy in front of Traefik's container. Don't like how much control it has right now.
