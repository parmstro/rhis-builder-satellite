#!/bin/bash
# Validate that pulp_container optimization is fully removed
# Run on the satellite host as root or with sudo

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

check() {
    local label="$1"
    local result="$2"
    local detail="$3"
    if [[ "$result" == "PASS" ]]; then
        printf "${GREEN}[PASS]${NC} %s\n" "$label"
        ((PASS++))
    elif [[ "$result" == "WARN" ]]; then
        printf "${YELLOW}[WARN]${NC} %s — %s\n" "$label" "$detail"
        ((WARN++))
    else
        printf "${RED}[FAIL]${NC} %s — %s\n" "$label" "$detail"
        ((FAIL++))
    fi
}

echo "============================================="
echo " Pulp Container Optimization State Validator"
echo " $(date)"
echo " Host: $(hostname -f)"
echo "============================================="
echo

# ── Database checks ──────────────────────────────────────────────

echo "── Database ──"

col_count=$(sudo -u postgres psql -d pulpcore -tAc \
    "SELECT count(*) FROM information_schema.columns
     WHERE table_name='container_containerremote'
     AND column_name='auto_discover_cosign';" 2>/dev/null)

if [[ "$col_count" == "0" ]]; then
    check "auto_discover_cosign column" "PASS"
else
    check "auto_discover_cosign column" "FAIL" "column still exists in container_containerremote"
fi

mig_count=$(sudo -u postgres psql -d pulpcore -tAc \
    "SELECT count(*) FROM django_migrations
     WHERE app = 'container'
     AND name LIKE '%0046%cosign%';" 2>/dev/null)

if [[ "$mig_count" == "0" ]]; then
    check "django_migrations record" "PASS"
else
    check "django_migrations record" "FAIL" "migration record still in django_migrations"
fi

latest_mig=$(sudo -u postgres psql -d pulpcore -tAc \
    "SELECT name FROM django_migrations
     WHERE app = 'container'
     ORDER BY id DESC LIMIT 1;" 2>/dev/null)

check "latest container migration" "PASS"
echo "       → $latest_mig"

echo

# ── Filesystem checks ────────────────────────────────────────────

echo "── Filesystem ──"

pco_path="/usr/lib/python3.12/site-packages/pulp_container"
if [[ ! -d "$pco_path" ]]; then
    pco_path=$(find /usr/lib/python3* -path "*/pulp_container/app" -type d 2>/dev/null | head -1 | sed 's|/app$||')
fi

if [[ -z "$pco_path" ]]; then
    check "pulp_container installation" "FAIL" "not found"
else
    check "pulp_container installation" "PASS"
    echo "       → $pco_path"
fi

mig_file="$pco_path/app/migrations/0046_containerremote_auto_discover_cosign.py"
if [[ ! -f "$mig_file" ]]; then
    check "migration file removed" "PASS"
else
    check "migration file removed" "FAIL" "$mig_file still exists"
fi

pycache_hits=$(find "$pco_path/app/migrations/__pycache__/" -name "*0046*" 2>/dev/null | wc -l)
if [[ "$pycache_hits" -eq 0 ]]; then
    check "migration pycache cleaned" "PASS"
else
    check "migration pycache cleaned" "WARN" "$pycache_hits cached files remain"
fi

# Verify Python files match RPM originals
rpm_name=$(rpm -qf "$pco_path/app/models.py" 2>/dev/null)
if [[ -n "$rpm_name" ]]; then
    rpm_diff=$(rpm -V "$rpm_name" 2>/dev/null | grep -E '(models\.py|sync_stages\.py|synchronize\.py)')
    if [[ -z "$rpm_diff" ]]; then
        check "Python files match RPM" "PASS"
    else
        check "Python files match RPM" "FAIL" "modified files detected"
        echo "$rpm_diff" | while read -r line; do
            echo "       → $line"
        done
    fi
else
    check "Python files match RPM" "WARN" "could not determine owning RPM"
fi

echo

# ── Optimization artifacts ───────────────────────────────────────

echo "── Optimization artifacts ──"

if [[ -d "/opt/pulp_container_optimization" ]]; then
    backup_count=$(find /opt/pulp_container_optimization/backups/ -maxdepth 1 -type d 2>/dev/null | wc -l)
    marker=$(find /opt/pulp_container_optimization -name "ROLLBACK_SUCCESS.txt" -o -name "DEPLOYMENT_SUCCESS.txt" 2>/dev/null | head -1)
    check "optimization directory" "WARN" "exists at /opt/pulp_container_optimization ($((backup_count - 1)) backups)"
    if [[ -n "$marker" ]]; then
        echo "       → last marker: $(basename $marker)"
        echo "       → $(head -2 $marker | tr '\n' ' ')"
    fi
else
    check "optimization directory" "PASS"
fi

echo

# ── Service checks ───────────────────────────────────────────────

echo "── Services ──"

for svc in pulpcore-api pulpcore-content pulpcore-worker@1 pulpcore-worker@2 pulpcore-worker@3 pulpcore-worker@4; do
    state=$(systemctl is-active "$svc" 2>/dev/null)
    if [[ "$state" == "active" ]]; then
        check "$svc" "PASS"
    else
        check "$svc" "FAIL" "state: $state"
    fi
done

echo

# ── API check ────────────────────────────────────────────────────

echo "── Pulp API ──"

http_code=$(curl -sk -o /dev/null -w '%{http_code}' "https://$(hostname -f)/pulp/api/v3/status/" 2>/dev/null)
if [[ "$http_code" == "200" ]]; then
    check "Pulp API responds" "PASS"
else
    check "Pulp API responds" "FAIL" "HTTP $http_code"
fi

echo

# ── Summary ──────────────────────────────────────────────────────

echo "============================================="
printf "Results: ${GREEN}%d PASS${NC}  ${YELLOW}%d WARN${NC}  ${RED}%d FAIL${NC}\n" "$PASS" "$WARN" "$FAIL"

if [[ "$FAIL" -eq 0 && "$WARN" -eq 0 ]]; then
    printf "${GREEN}System is clean — safe to re-run optimization install${NC}\n"
elif [[ "$FAIL" -eq 0 ]]; then
    printf "${YELLOW}System is mostly clean — review warnings before re-install${NC}\n"
else
    printf "${RED}System is NOT clean — resolve failures before re-install${NC}\n"
fi
echo "============================================="

exit $FAIL
