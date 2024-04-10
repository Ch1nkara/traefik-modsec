# traefik modsec interceptor
Simple traefik configuration that uses an external waf. 
Traefik is used as reverse proxy, submitting every request to an exteral WAF. The http response is replaced by the WAF one if http response code is 418.

__prerequistes__:
 - download latest stable traefik binary [here](https://github.com/traefik/traefik/releases) (tested with traefik 2.11.0)
 - have the website listening on localhost only
 - have a eestisinised/modsec-ng WAF runing

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
  ./configure_traefik.sh -d example.local -s certs -u -m http://example.local:8000 -b http://localhost:8080
```
 - zip the folder, scp to the webserver machine, unzip, `sudo chown www-data: -R traefik_bundle`
 - start traefik: 
 ```bash
 sudo -u www-data ./traefik --configFile static.yml
 #Or
 sudo -u www-data nohup ./traefik --configFile static.yml
 ```
 might require `sudo setcap 'cap_net_bind_service=+ep' /path/to/traefik` to allow non-privileged traefik to bind to port 80/443

## modsec plugin source code modifications
 - only return WAF response if http response code is 418 instead of >400
 - if an error occur during the plugin execution, pass the traffic instead of blocking it

## Dirty example on a single machine

### Summary
 - WAF       *:8000
 - WAF rules *:8001
 - website   localhost:8080
 - traefik   example.local:80, example.local:443

### website (only exposed to localhost)
```bash
cd ~/Downloads/temp
sudo python -m http.server -b localhost 8080
```

### waf 
 - Start the rule server
 - Configure and start eestisinised/modsec-ng (listennig on example.local:8000)

### configure and start traefik
```bash
./configure_traefik.sh -d example.local -s certs -u -m http://example.local:8000 -b http://localhost:8080
cd .. && sudo chown www-data: -R traefik-modsec && cd traefik-modsec
sudo -u www-data ./traefik --configFile static.yml
```
