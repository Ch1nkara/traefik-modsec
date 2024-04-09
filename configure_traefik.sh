#!/bin/bash

# Show usage
usage() {
    echo "Usage: $0 -d dns_name [-s path/to/cert/folder] [-u] [-m modsec_url]  [-b backend] [-h]"
    echo ""
    echo "Options:"
    echo "  -d, --dns_name     The website dns name that will serve as listenning point for traefik"
    echo "  -s, --secure       (Optional) enable tls mode. certificates and key must be present as tls.crt and tls.key"
    echo "  -u, --unsecure     (Optional) enable http mode. One of -u or -s is mandatory"
    echo "  -m, --modsec_url   (Optional) The url of the centralized WAF 'Washing Machine'"
    echo "  -b, --backend      (Optional) The website backend url. Default is http://localhost"
    echo "  -h, --help         (Optional) Show this menu."
    echo ""
    echo "Examples:"
    echo "  $0 -d example.local -u"
    echo "  $0 -d example.local -s certs -u -m  http://example.local:4444 -b http://localhost"
    exit 1
}

# Default values
MODSEC_URL=http://example.local:4444
TLS_PATH="certs"
BACKEND_URL=http://localhost
TLS_COMMENT="#"
HTTP_COMMENT="#"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -d|--dns_name)
            DNS_NAME="$2"
            shift
            shift
            ;;
        -s|--secure)
            TLS_PATH="$2"
            TLS_COMMENT=""
            shift
            shift
            ;;
        -u|--unsecure)
            HTTP_COMMENT=""
            shift
            ;;
        -m|--modsec_url)
            MODSEC_URL="$2"
            shift
            shift
            ;;
        -b|--backend)
            BACKEND_URL="$2"
            shift
            shift
            ;;
        -h| --help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Check for mandatory arguments
if [[ -z $DNS_NAME || -z $MODSEC_URL ]]; then
    echo "Mandatory arguments missing!"
    usage
fi

# Verify that one of --unsecure or --secure is set
if [[ ! -z $HTTP_COMMENT && ! -z $TLS_COMMENT ]]; then
    echo "one of --unsecure or --secure is mandatory"
    usage
fi

export DNS_NAME 
export TLS_PATH TLS_COMMENT HTTP_COMMENT
export MODSEC_URL BACKEND_URL 

# Configure Traefik with provided arguments
envsubst < dynamic.template > dynamic.yml
envsubst < static.template > static.yml

echo "Traefik is now configured, you can start it with: 'sudo -u www-data ./traefik --configFile static.yml'"
