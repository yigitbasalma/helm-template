# Multi-Environment Values Örneği

Base values dosyasında 15 env var tanımlı. Ortam dosyalarında sadece farklı olanlar override ediliyor.

## Dosyalar

| Dosya | İçerik |
|-------|--------|
| `values.yaml` | 15 env var + secret ref'ler + ortak config |
| `values-dev.yaml` | 4 override (DATABASE_HOST, LOG_LEVEL, APP_ENV, FEATURE_FLAG) |
| `values-staging.yaml` | 4 override (DATABASE_HOST, LOG_LEVEL, APP_ENV, CORS_ORIGINS) |
| `values-prod.yaml` | 6 override (DATABASE_HOST, DATABASE_POOL_SIZE, LOG_LEVEL, APP_ENV, CORS_ORIGINS, RATE_LIMIT) |

## Deploy Komutları

```bash
# Dev
helm install myapp . -f values.yaml -f values-dev.yaml

# Staging
helm install myapp . -f values.yaml -f values-staging.yaml

# Production
helm install myapp . -f values.yaml -f values-prod.yaml
```

## Nasıl Çalışır

`environmentsMap` bir map (dict) olduğu için Helm ikinci values dosyasını birincisiyle **merge** eder.

```
values.yaml:          DATABASE_HOST=db.default.svc, LOG_LEVEL=info, REDIS_HOST=redis.default.svc
values-prod.yaml:     DATABASE_HOST=db-prod.internal, LOG_LEVEL=warn
                      ─────────────────────────────────────────────
Sonuç:                DATABASE_HOST=db-prod.internal, LOG_LEVEL=warn, REDIS_HOST=redis.default.svc
```

Override edilen key'ler prod'dan gelir, geri kalanlar base'den aynen kalır.

## Ne Zaman `environments` vs `environmentsMap` Kullanılır

| Durum | Kullan |
|-------|--------|
| Basit key-value, ortama göre değişebilir | `environmentsMap` |
| Secret reference (`valueFrom.secretKeyRef`) | `environments` |
| Field reference (`valueFrom.fieldRef`) | `environments` |
| ConfigMap reference (`valueFrom.configMapKeyRef`) | `environments` |

İkisi birlikte kullanılabilir — template her ikisini de aynı `env:` bloğuna render eder.