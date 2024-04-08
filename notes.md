docker run -it --rm busybox

sudo ./traefik --configFile static_conf.yaml

cd ~/Downloads/temp
sudo python -m http.server -b localhost 80