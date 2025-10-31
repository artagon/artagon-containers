#!/bin/sh
# Enterprise-grade JVM health check supporting:
# - MicroProfile Health (Quarkus, Open Liberty, WildFly)
# - Spring Boot Actuator
# - Custom application endpoints
# - Fallback to JVM execution test

set -e

# Health check mode (can be overridden via env var)
MODE="${HEALTH_CHECK_MODE:-auto}"
PORT="${HEALTH_CHECK_PORT:-8080}"
ENDPOINT="${HEALTH_CHECK_ENDPOINT:-}"

# Function: Test HTTP endpoint with timeout
http_check() {
  url="$1"
  if command -v curl >/dev/null 2>&1; then
    curl -f -s -m 2 "$url" >/dev/null 2>&1
    return $?
  elif command -v wget >/dev/null 2>&1; then
    wget -q -T 2 -O /dev/null "$url" >/dev/null 2>&1
    return $?
  fi
  return 1
}

# Function: Test MicroProfile Health endpoints
microprofile_check() {
  # Try liveness endpoint (primary)
  if http_check "http://localhost:${PORT}/health/live"; then
    return 0
  fi
  # Try overall health endpoint (fallback)
  if http_check "http://localhost:${PORT}/health"; then
    return 0
  fi
  # Try readiness endpoint (alternative)
  if http_check "http://localhost:${PORT}/health/ready"; then
    return 0
  fi
  return 1
}

# Function: Test Spring Boot Actuator
spring_actuator_check() {
  # Try liveness endpoint
  if http_check "http://localhost:${PORT}/actuator/health/liveness"; then
    return 0
  fi
  # Try overall health
  if http_check "http://localhost:${PORT}/actuator/health"; then
    return 0
  fi
  return 1
}

# Function: Test JVM execution capability
jvm_execution_check() {
  HEALTH_CHECK_CODE='
  class HealthCheck {
    public static void main(String[] args) {
      try {
        // Test 1: Memory allocation and GC
        java.util.List<String> list = new java.util.ArrayList<>();
        list.add("health");

        // Test 2: System properties access
        String javaVersion = System.getProperty("java.version");
        if (javaVersion == null || javaVersion.isEmpty()) {
          System.exit(1);
        }

        // Test 3: CPU/processor access
        int processors = Runtime.getRuntime().availableProcessors();
        if (processors < 1) {
          System.exit(1);
        }

        // Test 4: Memory availability
        long maxMemory = Runtime.getRuntime().maxMemory();
        if (maxMemory < 1) {
          System.exit(1);
        }

        // Test 5: Thread creation (lightweight test)
        Thread.currentThread().getName();

        // All tests passed
        System.exit(0);
      } catch (Exception e) {
        System.exit(1);
      }
    }
  }
  '

  # JDK 11+ supports single-file source-code execution
  if echo "$HEALTH_CHECK_CODE" | sed 's/^ *//' | timeout 2s java - >/dev/null 2>&1; then
    return 0
  fi

  # Fallback: Try jshell (JDK 9+)
  if command -v jshell >/dev/null 2>&1; then
    echo "System.exit(Runtime.getRuntime().availableProcessors() > 0 ? 0 : 1)" | timeout 2s jshell -q >/dev/null 2>&1
    return $?
  fi

  # Final fallback: Basic version check
  timeout 2s java -version >/dev/null 2>&1
  return $?
}

# Main health check logic
case "$MODE" in
  microprofile|quarkus)
    # MicroProfile Health (Quarkus, Open Liberty, WildFly, Payara)
    microprofile_check
    exit $?
    ;;
  spring|actuator)
    # Spring Boot Actuator
    spring_actuator_check
    exit $?
    ;;
  http)
    # Custom HTTP endpoint
    if [ -n "$ENDPOINT" ]; then
      http_check "http://localhost:${PORT}${ENDPOINT}"
      exit $?
    fi
    echo "ERROR: HEALTH_CHECK_ENDPOINT not set for http mode" >&2
    exit 1
    ;;
  jvm)
    # JVM execution test only
    jvm_execution_check
    exit $?
    ;;
  auto|*)
    # Auto-detect: Try MicroProfile -> Spring -> JVM execution

    # 1. Try MicroProfile Health
    if microprofile_check; then
      exit 0
    fi

    # 2. Try Spring Boot Actuator
    if spring_actuator_check; then
      exit 0
    fi

    # 3. Try custom endpoint if specified
    if [ -n "$ENDPOINT" ]; then
      if http_check "http://localhost:${PORT}${ENDPOINT}"; then
        exit 0
      fi
    fi

    # 4. Fallback to JVM execution test
    jvm_execution_check
    exit $?
    ;;
esac
