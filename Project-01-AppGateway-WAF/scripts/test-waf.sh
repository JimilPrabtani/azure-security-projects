#!/bin/bash
# =============================================================================
# WAF Testing Script — Validate WAF protection rules
# =============================================================================
# Usage: ./test-waf.sh <application-gateway-ip>
# =============================================================================

set -euo pipefail

if [ -z "${1:-}" ]; then
    echo "Usage: ./test-waf.sh <application-gateway-ip>"
    echo "Example: ./test-waf.sh 20.120.1.100"
    exit 1
fi

APPGW_IP="$1"
BASE_URL="http://$APPGW_IP"
PASS=0
FAIL=0

echo "============================================"
echo " WAF Protection Test Suite"
echo " Target: $BASE_URL"
echo "============================================"
echo ""

# Test function
run_test() {
    local TEST_NAME="$1"
    local EXPECTED_STATUS="$2"
    local CURL_ARGS=("${@:3}")

    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${CURL_ARGS[@]}" 2>/dev/null || echo "000")

    if [ "$STATUS" = "$EXPECTED_STATUS" ]; then
        echo "[PASS] $TEST_NAME (HTTP $STATUS)"
        ((PASS++))
    else
        echo "[FAIL] $TEST_NAME (Expected: $EXPECTED_STATUS, Got: $STATUS)"
        ((FAIL++))
    fi
}

# Test 1: Normal traffic should pass
echo "--- Normal Traffic Tests ---"
run_test "Normal GET request" "200" "$BASE_URL/"

# Test 2: SQL Injection should be blocked (403)
echo ""
echo "--- SQL Injection Tests ---"
run_test "SQL Injection (OR 1=1)" "403" "$BASE_URL/?id=1%27%20OR%20%271%27%3D%271"
run_test "SQL Injection (UNION SELECT)" "403" "$BASE_URL/?id=1%20UNION%20SELECT%20*%20FROM%20users"
run_test "SQL Injection (DROP TABLE)" "403" "$BASE_URL/?q=1;DROP%20TABLE%20users--"

# Test 3: XSS should be blocked (403)
echo ""
echo "--- Cross-Site Scripting (XSS) Tests ---"
run_test "XSS (script tag)" "403" "$BASE_URL/?q=%3Cscript%3Ealert(%27xss%27)%3C/script%3E"
run_test "XSS (img onerror)" "403" "$BASE_URL/?q=%3Cimg%20src=x%20onerror=alert(1)%3E"

# Test 4: Suspicious User Agent should be blocked (403)
echo ""
echo "--- Suspicious User Agent Tests ---"
run_test "User-Agent: sqlmap" "403" -H "User-Agent: sqlmap/1.0" "$BASE_URL/"
run_test "User-Agent: nikto" "403" -H "User-Agent: nikto/2.1.6" "$BASE_URL/"
run_test "User-Agent: nmap" "403" -H "User-Agent: nmap scripting engine" "$BASE_URL/"

# Test 5: Path traversal should be blocked (403)
echo ""
echo "--- Path Traversal Tests ---"
run_test "Path traversal (etc/passwd)" "403" "$BASE_URL/../../etc/passwd"

# Results
echo ""
echo "============================================"
echo " Test Results: $PASS passed, $FAIL failed"
echo "============================================"

if [ "$FAIL" -gt 0 ]; then
    echo "WARNING: Some WAF tests failed. Review WAF policy configuration."
    exit 1
else
    echo "All WAF tests passed successfully!"
    exit 0
fi
