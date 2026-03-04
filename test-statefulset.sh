#!/bin/bash

# Test script for StatefulSet functionality
set -e

echo "=== Testing Base Helm Template StatefulSet Support ==="
echo ""

# Test 1: Deployment mode (default)
echo "Test 1: Default Deployment mode"
helm template test-deployment . --set workloadType=deployment > /tmp/test-deployment.yaml
if grep -q "kind: Deployment" /tmp/test-deployment.yaml && ! grep -q "kind: StatefulSet" /tmp/test-deployment.yaml; then
    echo "✅ Deployment mode works correctly"
else
    echo "❌ Deployment mode failed"
    exit 1
fi
echo ""

# Test 2: StatefulSet mode
echo "Test 2: StatefulSet mode"
helm template test-statefulset . --set workloadType=statefulset > /tmp/test-statefulset.yaml
if grep -q "kind: StatefulSet" /tmp/test-statefulset.yaml && ! grep -q "kind: Deployment" /tmp/test-statefulset.yaml; then
    echo "✅ StatefulSet mode works correctly"
else
    echo "❌ StatefulSet mode failed"
    exit 1
fi
echo ""

# Test 3: Headless service for StatefulSet
echo "Test 3: Headless service creation"
if grep -q "clusterIP: None" /tmp/test-statefulset.yaml; then
    echo "✅ Headless service created for StatefulSet"
else
    echo "❌ Headless service not found"
    exit 1
fi
echo ""

# Test 4: Basic StatefulSet example
echo "Test 4: Basic StatefulSet example"
helm template test-basic . -f examples/statefulset-basic-values.yaml > /tmp/test-basic.yaml
if grep -q "volumeClaimTemplates:" /tmp/test-basic.yaml && grep -q "name: data" /tmp/test-basic.yaml; then
    echo "✅ Basic StatefulSet example works"
else
    echo "❌ Basic StatefulSet example failed"
    exit 1
fi
echo ""

# Test 5: Multiple PVCs example
echo "Test 5: Multiple PVCs StatefulSet example"
helm template test-postgres . -f examples/statefulset-multiple-pvcs-values.yaml > /tmp/test-postgres.yaml
if grep -q "name: data" /tmp/test-postgres.yaml && grep -q "name: logs" /tmp/test-postgres.yaml && grep -q "name: wal" /tmp/test-postgres.yaml; then
    echo "✅ Multiple PVCs example works"
else
    echo "❌ Multiple PVCs example failed"
    exit 1
fi
echo ""

# Test 6: Redis cluster example
echo "Test 6: Redis cluster example"
helm template test-redis . -f examples/statefulset-redis-cluster-values.yaml > /tmp/test-redis.yaml
if grep -q "redis-data" /tmp/test-redis.yaml && grep -q "podAntiAffinity" /tmp/test-redis.yaml; then
    echo "✅ Redis cluster example works"
else
    echo "❌ Redis cluster example failed"
    exit 1
fi
echo ""

# Test 7: Helm lint
echo "Test 7: Helm lint"
if helm lint . > /dev/null 2>&1; then
    echo "✅ Helm lint passed"
else
    echo "❌ Helm lint failed"
    exit 1
fi
echo ""

# Test 8: Backward compatibility (no workloadType specified)
echo "Test 8: Backward compatibility"
helm template test-default . > /tmp/test-default.yaml
if grep -q "kind: Deployment" /tmp/test-default.yaml; then
    echo "✅ Backward compatibility maintained (defaults to Deployment)"
else
    echo "❌ Backward compatibility broken"
    exit 1
fi
echo ""

# Cleanup
rm -f /tmp/test-*.yaml

echo "=== All Tests Passed! ==="
echo ""
echo "Summary:"
echo "  ✅ Deployment mode"
echo "  ✅ StatefulSet mode"
echo "  ✅ Headless service"
echo "  ✅ Basic example"
echo "  ✅ Multiple PVCs"
echo "  ✅ Redis cluster"
echo "  ✅ Helm lint"
echo "  ✅ Backward compatibility"
echo ""
echo "StatefulSet support is ready to use!"
