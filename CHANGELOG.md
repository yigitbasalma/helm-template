# Changelog

## [Unreleased] - 2024-12-06

### Added

#### IngressRoute Support
- **HTTP/HTTPS IngressRoute template** (`templates/ingressroute.yaml`)
  - Automatic TLS certificate provisioning via cert-manager
  - Built-in HTTP to HTTPS redirect with middleware
  - Support for custom Traefik middlewares
  - Optional path-based routing
  - Configurable cert-manager Issuer/ClusterIssuer

- **TCP IngressRoute template** (`templates/ingressroute-tcp.yaml`)
  - TCP routing for databases and custom protocols
  - TLS support with termination or passthrough
  - Configurable entryPoints
  - Certificate management for TCP services

#### Configuration
- Added `ingressRoute` section to values.yaml:
  - `enabled`: Enable/disable HTTP IngressRoute
  - `host`: Hostname for routing
  - `path`: Optional path prefix
  - `httpsRedirect`: Auto HTTP→HTTPS redirect
  - `certIssuer`: cert-manager issuer name
  - `certIssuerKind`: Issuer or ClusterIssuer
  - `annotations`: Custom annotations
  - `middlewares`: List of Traefik middlewares

- Added `ingressRouteTCP` section to values.yaml:
  - `enabled`: Enable/disable TCP IngressRoute
  - `host`: Hostname for SNI routing
  - `entryPoints`: List of Traefik TCP entryPoints
  - `tls.enabled`: Enable TLS
  - `tls.certIssuer`: cert-manager issuer
  - `tls.passthrough`: TLS passthrough mode

#### Documentation
- `INGRESSROUTE.md`: Comprehensive guide with examples
- `QUICKSTART.md`: Quick reference for common patterns
- `values-example.yaml`: Complete example configuration

### Features

#### Certificate Management
- Automatic certificate creation via cert-manager
- Support for Let's Encrypt and custom issuers
- Separate certificates for HTTP and TCP routes
- Configurable issuer type (Issuer/ClusterIssuer)

#### HTTP/HTTPS Routing
- Automatic HTTPS redirect with middleware
- Path-based routing support
- Custom middleware integration
- Flexible entryPoint configuration

#### TCP Routing
- SNI-based routing for TCP services
- TLS termination at Traefik
- TLS passthrough for end-to-end encryption
- Support for database services (PostgreSQL, MongoDB, etc.)

### Compatibility
- Works alongside existing `ingress` configuration
- No breaking changes to existing values
- Traefik v2+ required
- cert-manager v1+ required

### Migration Notes
- Existing charts using standard Ingress can continue to work
- IngressRoute provides better Traefik integration
- Simpler configuration for TLS and redirects
- See INGRESSROUTE.md for migration guide
