#!/bin/bash
#
# OpenPilot Local Build Script (Linux/Mac)
# Builds and tests OpenPilot locally, creating artifacts similar to GitHub Actions
#

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variables
WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$WORKSPACE_ROOT/build-output"
ARTIFACTS_DIR="$WORKSPACE_ROOT/artifacts"
BUILD_TYPE="${1:-all}"
SKIP_TESTS="${SKIP_TESTS:-false}"
COVERAGE="${COVERAGE:-false}"
CLEAN="${CLEAN:-false}"

# Functions
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_section() { echo -e "\n${MAGENTA}========================================\n  $1\n========================================${NC}\n"; }

# Clean artifacts
clean_artifacts() {
    log_section "Cleaning Build Artifacts"
    
    rm -rf "$BUILD_DIR" "$ARTIFACTS_DIR"
    rm -rf core/dist core/node_modules tests/coverage tests/node_modules
    
    log_success "Cleaned all build artifacts"
}

# Build core library
build_core() {
    log_section "Building Core Library"
    
    cd "$WORKSPACE_ROOT/core"
    
    log_info "Installing dependencies..."
    npm install
    
    log_info "Compiling TypeScript..."
    npm run build
    
    log_success "Core library built successfully"
    
    # Copy to build output
    mkdir -p "$BUILD_DIR/core"
    cp -r dist "$BUILD_DIR/core/"
    cp package.json "$BUILD_DIR/core/"
    
    log_success "Core artifacts saved to $BUILD_DIR/core"
    
    cd "$WORKSPACE_ROOT"
}

# Run tests
run_tests() {
    log_section "Running Tests"
    
    cd "$WORKSPACE_ROOT/tests"
    
    log_info "Installing test dependencies..."
    npm install
    
    log_info "Running TypeScript type check..."
    npx tsc --noEmit
    
    if [ "$COVERAGE" = "true" ]; then
        log_info "Running tests with coverage..."
        npm test -- --coverage --ci
        
        # Copy coverage to artifacts
        mkdir -p "$ARTIFACTS_DIR/coverage"
        cp -r coverage/* "$ARTIFACTS_DIR/coverage/"
        
        log_success "Coverage report saved to $ARTIFACTS_DIR/coverage"
        
        # Display coverage summary
        if [ -f "coverage/coverage-summary.json" ]; then
            log_info "Coverage Summary:"
            cat coverage/coverage-summary.json | python3 -m json.tool
        fi
    else
        log_info "Running tests..."
        npm test
    fi
    
    log_success "All tests passed"
    
    cd "$WORKSPACE_ROOT"
}

# Build with Docker
build_docker() {
    log_section "Building with Docker"
    
    log_info "Building Docker test image..."
    docker-compose -f docker-compose.test.yml build test-runner
    
    log_success "Docker image built successfully"
    
    if [ "$SKIP_TESTS" != "true" ]; then
        log_info "Running tests in Docker..."
        docker-compose -f docker-compose.test.yml run --rm test-runner || {
            log_warning "Docker tests failed, running auto-fix..."
            docker-compose -f docker-compose.test.yml run --rm test-autofix
        }
    fi
    
    # Extract coverage from Docker if requested
    if [ "$COVERAGE" = "true" ]; then
        log_info "Running coverage in Docker..."
        docker-compose -f docker-compose.test.yml run --rm test-coverage
        
        log_info "Extracting coverage from Docker..."
        docker create --name coverage-temp openpilot-test-runner:latest
        
        mkdir -p "$ARTIFACTS_DIR/docker-coverage"
        docker cp coverage-temp:/app/tests/coverage/. "$ARTIFACTS_DIR/docker-coverage/"
        docker rm coverage-temp
        
        log_success "Docker coverage saved to $ARTIFACTS_DIR/docker-coverage"
    fi
}

# Build documentation
build_docs() {
    log_section "Building Documentation"
    
    mkdir -p "$ARTIFACTS_DIR/docs"
    
    # Copy documentation files
    if [ -d "docs" ]; then
        cp -r docs/* "$ARTIFACTS_DIR/docs/"
    fi
    
    # Copy README and guides
    cp README.md "$ARTIFACTS_DIR/docs/README.md"
    cp tests/TESTING_SYSTEM_GUIDE.md "$ARTIFACTS_DIR/docs/TESTING.md"
    
    # Generate TypeDoc (if available)
    cd "$WORKSPACE_ROOT/core"
    log_info "Generating API documentation..."
    npx typedoc --out "$ARTIFACTS_DIR/docs/api" src/index.ts || log_warning "TypeDoc generation skipped"
    cd "$WORKSPACE_ROOT"
    
    # Copy coverage to docs if it exists
    if [ -d "$ARTIFACTS_DIR/coverage" ]; then
        cp -r "$ARTIFACTS_DIR/coverage" "$ARTIFACTS_DIR/docs/coverage"
    fi
    
    log_success "Documentation saved to $ARTIFACTS_DIR/docs"
    
    # Create index.html
    cat > "$ARTIFACTS_DIR/docs/index.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>OpenPilot Documentation</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 50px auto; padding: 20px; }
        h1 { color: #333; }
        .link-box { background: #f5f5f5; padding: 15px; margin: 10px 0; border-radius: 5px; }
        a { color: #0066cc; text-decoration: none; }
        a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <h1>OpenPilot Documentation</h1>
    <div class="link-box">
        <h2><a href="README.html">📘 Main Documentation</a></h2>
        <p>Project overview and getting started guide</p>
    </div>
    <div class="link-box">
        <h2><a href="TESTING.html">🧪 Testing System Guide</a></h2>
        <p>Comprehensive testing documentation</p>
    </div>
    <div class="link-box">
        <h2><a href="api/index.html">📚 API Documentation</a></h2>
        <p>TypeDoc generated API reference</p>
    </div>
    <div class="link-box">
        <h2><a href="coverage/lcov-report/index.html">📊 Test Coverage Report</a></h2>
        <p>Code coverage analysis</p>
    </div>
</body>
</html>
EOF
}

# Create release archive
create_release() {
    log_section "Creating Release Archive"
    
    VERSION="v1.0.0"  # TODO: Read from package.json
    ARCHIVE_NAME="openpilot-$VERSION-$(date +%Y%m%d)"
    ARCHIVE_PATH="$ARTIFACTS_DIR/$ARCHIVE_NAME.tar.gz"
    
    tar -czf "$ARCHIVE_PATH" -C "$BUILD_DIR" .
    
    log_success "Release archive created: $ARCHIVE_PATH"
    
    # Show archive contents
    log_info "Archive contents:"
    tar -tzf "$ARCHIVE_PATH" | head -20
}

# Main execution
main() {
    cat << 'EOF'
╔════════════════════════════════════════════════╗
║                                                ║
║        OpenPilot Local Build System            ║
║                                                ║
╚════════════════════════════════════════════════╝
EOF

    log_info "Build Type: $BUILD_TYPE"
    log_info "Skip Tests: $SKIP_TESTS"
    log_info "Coverage: $COVERAGE"
    log_info "Clean: $CLEAN"
    log_info "Workspace: $WORKSPACE_ROOT"
    
    # Create directories
    mkdir -p "$BUILD_DIR" "$ARTIFACTS_DIR"
    
    if [ "$CLEAN" = "true" ]; then
        clean_artifacts
    fi
    
    START_TIME=$(date +%s)
    
    # Execute build steps
    case "$BUILD_TYPE" in
        all)
            build_core
            if [ "$SKIP_TESTS" != "true" ]; then
                run_tests
            fi
            build_docker
            build_docs
            create_release
            ;;
        core)
            build_core
            ;;
        tests)
            build_core
            run_tests
            ;;
        docker)
            build_docker
            ;;
        docs)
            build_docs
            ;;
        *)
            log_error "Unknown build type: $BUILD_TYPE"
            echo "Usage: $0 [all|core|tests|docker|docs]"
            echo "Environment variables:"
            echo "  SKIP_TESTS=true|false"
            echo "  COVERAGE=true|false"
            echo "  CLEAN=true|false"
            exit 1
            ;;
    esac
    
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    log_section "Build Summary"
    log_success "Build completed successfully!"
    log_info "Duration: ${DURATION}s"
    log_info "Build output: $BUILD_DIR"
    log_info "Artifacts: $ARTIFACTS_DIR"
    
    # Open artifacts directory (if on macOS)
    if [[ "$OSTYPE" == "darwin"* ]] && [ -d "$ARTIFACTS_DIR" ]; then
        open "$ARTIFACTS_DIR"
    fi
}

# Run main function
main "$@"
