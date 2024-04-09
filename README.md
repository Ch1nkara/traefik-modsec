# traefik modsec interceptor
Simple traefik configuration that uses an external waf. 
Traefik is used as reverse proxy, submitting every request to an exteral WAF and blocking if the WAF returns http code 400.

__prerequistes__:
 - download latest stable traefik binary [here](https://github.com/traefik/traefik/releases)
 - have the website listening on localhost only
 - have a owasp/modsecurity WAF runing

 __Usage__:
 - Configure traefik:
```text
Usage: ./configure_traefik.sh -d dns_name [-s path/to/cert/folder] [-u] [-m modsec_url]  [-b backend] [-h]

Options:
  -d, --dns_name     The website dns name that will serve as listenning point for traefik
  -s, --secure       (Optional) enable tls mode. certificates and key must be present as tls.crt and tls.key
  -u, --unsecure     (Optional) enable http mode. One of -u or -s is mandatory
  -m, --modsec_url   (Optional) The url of the centralized WAF 'Washing Machine'
  -b, --backend      (Optional) The website backend url. Default is http://localhost
  -h, --help         (Optional) Show this menu.

Examples:
  ./configure_traefik.sh -d example.local -u
  ./configure_traefik.sh -d example.local -s certs -u -m  http://example.local:4444 -b http://localhost
```
 - zip the folder, scp to the webserver machine, unzip, `chown www-data: -R traefik_bundle`
 - start traefik: 
 ```bash
 sudo -u www-data ./traefik --configFile static.yml
 #Or
 sudo -u www-data nohup ./traefik --configFile static.yml
 ```
 might require `sudo setcap 'cap_net_bind_service=+ep' /path/to/traefik` to allow non-privileged traefik to bind to port 80/443

## modsec plugin source code modifications
 - only return WAF response if http code is 403 instead of >400
 - if an error occur during the plugin execution, pass the traffic

## Dirty example on a single machine

### Summary
 - WAF       *:4444
 - website   localhost:80
 - fake      *:8000
 - traefik   example.local:80

### website (only exposed to localhost)
```bash
cd ~/Downloads/temp
sudo python -m http.server -b localhost 80
```

### fake server
__Used ad BACKEND for the WAF__
```bash
cd ~/Downloads/temp2
python -m http.server 8000
```
contains only index.html -> "fake"

### waf 
`docker run -p 4444:80 -e "BACKEND=http://example.local:8000" owasp/modsecurity-crs:apache`

### start traefik
`sudo -u www-data ./traefik --configFile static_conf.yaml`
