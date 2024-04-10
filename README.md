# traefik modsec interceptor
Simple traefik configuration that uses an external waf. 
Traefik is used as reverse proxy, submitting every request to an exteral WAF. The http response is replaced by the WAF one if http response code is 418.

__prerequistes__:
 - have the website listening on localhost:8080 only
 - have a eestisinised/modsec-ng WAF runing

 __Usage__:
`ansible-playbook playbook.yml`

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
 - Configure and start eestisinised/modsec-ng (listennig to *:8000)

### configure and start traefik
run the playbook from a configured ansible
