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

## Example inventory in ls24 format: inv-example

 - uses definition of local VMs mimicking the various configurations
 - run it with `ansible-playbook -i ./inv-example --limit  test_vm_ipv4  playbook.yml`
 - non standard (pure 80/443 single service) sites are added in host_vars

## Example using Wayren exercice

### Summary
 - WAF       waf.personal.url:4444 (waf running on dedicated server, port exposed to internet)
 - WAF rules localhost:4445 (runing on my personal, internet exposed, server))
 - website   localhost:8080
 - traefik   example.local:80, *:443

### Prerequites
_Anisible_, configuration on local machine:
- /etc/ansible/hosts:
```yaml
[webserver]
webserver.local
```
- ~/.ssh/config:
```text
Host webserver.local
 Hostname localhost
 User root
 Port 2222
```
- ssh key added to webserver to allow Ansible authentication
- tls cert and key persent on local machine under `roles/traefik-build-bundle/files/certs/tls.crt`

_Wayren/Docker adjustments_:
- tunnels mounted between local machine and Wayren webserver: (need to bind localhost:80 and localhost:443 because of reverse proxy)
```bash
ssh -o PreferredAuthentications=publickey,password -J web_vincent@ls24.wayren.ee -L 80:localhost:80 -L 443:localhost:443 -L 8432:localhost:5432 -L 2222:localhost:22 root@172.17.0.20
```
- because the Wayren env lacks DNS resolution:
  - webserver /etc/hosts: add `172.17.0.20 example.local`
  - local machine /etc/hosts: add `127.0.0.1 example.local`
  - webserver /app/exercice/settings.py: replace `ALLOWED_HOSTS = []` with `ALLOWED_HOSTS = ["example.local"]` and restart django (`/usr/bin/poetry run uwsgi -c /etc/uwsgi.ini &`)

### waf (waf.personal.url)
 - Start the rule server
 - Configure and start eestisinised/modsec-ng (listennig to *:4444, exposed to internet)

### configure and start traefik
_Note that before configuring and running traefi, I added tasks to expose the server only to localhost_
run the playbook:
```yaml
---
- name: Build the traefik bundle locally
  hosts: localhost
  tasks:
    - name: Build the traefik bundle
      include_role:
        name: traefik-build-bundle
      vars:
        dns_name: example.local
        centralized_waf_url: http://internet_exposed_waf_url:4444
        backend_url: http://localhost:8080
        enable_http: true
        enable_tls: true
        tls_crt_path: "files/certs/tls.crt"
        tls_key_path: "files/certs/tls.key"
        unprivileged_user: www-data

### APP specific tasks to expose nginx to localhost only
- name: Expose website to localhost only
  hosts: webserver
  tasks:
    - name: Edit nginx configuration - http port
      replace:
        path: /etc/nginx/nginx.conf
        regexp: 'listen 80'
        replace: "listen 127.0.0.1:8080"
    - name: Edit nginx configuration - ssl port
      replace:
        path: /etc/nginx/nginx.conf
        regexp: 'listen 443 ssl'
        replace: "listen 127.0.0.1:8443 ssl"
    - name: restart nginx (for some unknown reason reload does not work)
      shell: /etc/init.d/nginx restart
###

- name: Deploy the traefik bundle to the webserver
  hosts: webserver
  tasks:
    - name: deploy traefik bundle
      include_role: 
        name: traefik-deploy-bundle
      vars:
        bundle_local_path: traefik_bundle.tar.gz
```

__NOTES__:

- the build-bundle can be done beforhand
- the deploy-bundle role had to be adapted as follow in roles/traefik-deploy-bundle/tasks/main.yml:
 ```yaml
 #fix nedded for wayren exercice 
#- name: Extract the bundle archive
#  unarchive:
#    src: "traefik_bundle.tar.gz"
#    dest: "/opt"
#    remote_src: true
- name: Extract the bundle archive
  shell: cd /opt && tar xvf ~/traefik_bundle.tar.gz && cd ~
 ```
 ```yaml
# fix nedded for wayren exercice 
#- name: reload daemons
#  systemd:
#    daemon_reload: true
#- name: Start traefik
#  systemd:
#      name: traefik
#      state: started
- name: Start traefik
  shell: cd /opt/traefik_bundle && nohup su www-data -s /bin/bash -c "/opt/traefik_bundle/traefik --configFile static.yml" >log.txt 2>&1 &
 ```

 ### Verification
 - make sure traefik run as expected (chek for errors in webserver: /opt/traefik-bundle/log.txt)
 - connect to http://example.local and https://example.local -> web site is ok
 - connect to http://example.local/?test=../../etc/passwd -> forbidden, error 418
