# Changelog

## [Unreleased] - 2024-12-06

### Added

#### StatefulSet Support
- **StatefulSet template** (`templates/statefulset.yaml`)
  - Support for both Deployment and StatefulSet workload types
  - Configurable via `workloadType` field (deployment/statefulset)
  - Volume claim templates for automatic PVC creation per pod
  - Multiple volume claim templates support
  - Automatic headless service creation for StatefulSet
  - Stable pod identity and DNS names
  - Ordered pod creation and deletion

#### Configuration
- Added `workloadType` field to values.yaml (default: deployment)
- Added `statefulset` section to values.yaml:
  - `volumeClaimTemplates`: List of volume claim templates
  - Support for labels, annotations, accessModes, storage, storageClassName
  - Support for selector, volumeMode, and other PVC options

#### Templates
- Modified `templates/deployment.yaml`: Conditional rendering based on workloadType
- Modified `templates/service.yaml`: Added headless service for StatefulSet
- Created `templates/statefulset.yaml`: Complete StatefulSet implementation

#### Documentation
- `STATEFULSET.md`: Complete guide with examples and best practices
- `STATEFULSET-SUMMARY.md`: Implementation summary
- `examples/statefulset-quickstart.md`: Quick start guide
- Updated `README.md` with StatefulSet references
- Updated `examples/README.md` with StatefulSet examples

#### Examples
- `examples/statefulset-basic-values.yaml`: Basic StatefulSet with single volume
- `examples/statefulset-multiple-pvcs-values.yaml`: PostgreSQL with multiple volumes
- `examples/statefulset-redis-cluster-values.yaml`: Redis cluster configuration

### Features

#### Workload Type Selection
- Choose between Deployment (stateless) or StatefulSet (stateful)
- Backward compatible - defaults to Deployment
- No breaking changes to existing configurations

#### Volume Management
- Volume claim templates for StatefulSet
- Automatic PVC creation per pod replica
- Multiple volume claim templates per StatefulSet
- Support for different storage classes per volume
- Labels and annotations on volume claims

#### Pod Identity
- Stable hostname: `<statefulset-name>-<ordinal>`
- Stable DNS: `<pod-name>.<headless-service>.<namespace>.svc.cluster.local`
- Persistent storage follows pod across rescheduling
- Ordered scaling and updates

### Use Cases
- Databases (PostgreSQL, MySQL, MongoDB)
- Distributed systems (Kafka, Zookeeper, Elasticsearch)
- Cache servers (Redis, Memcached)
- Applications requiring stable network identity
- Applications needing persistent storage per replica

### Compatibility
- Fully backward compatible
- Works with existing features (ConfigMaps, PVCs, Services, etc.)
- Compatible with pod anti-affinity and other scheduling features
- No changes required for existing Deployment-based charts

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
