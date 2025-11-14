Koleksi pribadi
Untuk pemasangan :
```bash
git clone https://github.com/adisutomo89/VPNL2TP_genieacs.git
cd VPNL2TP_genieacs
chmod +x genieacs.sh
sudo bash genieacs.sh

chmod +x vpnsetup.sh
sudo bash vpnsetup.sh
```
Parameter genieacs
```bash
cd parameter
mongorestore --db genieacs --drop .
systemctl restart genieacs-{cwmp,ui,nbi}

#cek logs
journalctl -f -u genieacs-cwmp
```
```bash
sudo nano /etc/ppp/ip-up
# Route otomatis untuk PPP L2TP
if [ "$PPP_IFACE" = "ppp0" ]; then
    ip route add 12.5.89.0/24 dev ppp0 || true
fi

sudo systemctl restart xl2tpd
```

Mikrotik
```bash
/interface list
add name=PPPOE comment="List untuk semua PPPoE client"

/system scheduler
add name=AutoPPPoEtoList interval=1m on-event="/interface list member remove [find list=PPPOE]; :foreach i in=[/interface find where type~\"pppoe\"] do={/interface list member add list=PPPOE interface=\$i}" comment="Otomatis masukkan semua PPPoE ke list"

/ip firewall nat
add chain=srcnat src-address=192.168.42.0/24 out-interface-list=PPPOE action=masquerade comment="Auto NAT untuk trafik L2TP ke semua PPPoE"

#test
/tool sniffer quick interface=genieacs ip-protocol=icmp
```
OPSIONAL FIREWALL
```bash
# Hapus aturan lama (biar bersih)
sudo ufw --force reset

# Set default policy
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH dari mana saja
sudo ufw allow 22/tcp comment 'SSH remote access'

# Allow CWMP (CPE connect) dari mana saja
sudo ufw allow 7547/tcp comment 'GenieACS CWMP'

# Allow GUI dari mana saja
sudo ufw allow 3000/tcp comment 'GenieACS Web GUI'

# Allow NBI dan FileServer hanya dari jaringan lokal
sudo ufw allow from 192.168.42.0/24 to any port 7557 proto tcp comment 'GenieACS NBI internal only'
sudo ufw allow from 192.168.42.0/24 to any port 7567 proto tcp comment 'GenieACS FileServer internal only'

# Aktifkan firewall
sudo ufw --force enable

# Lihat hasil
sudo ufw status numbered


#melihat logs
sudo tail -f /var/log/genieacs/genieacs-cwmp-access.log

#logrotate
sudo nano /etc/logrotate.d/genieacs

/var/log/genieacs/*.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    create 644 root root
}

#cek
sudo logrotate -f /etc/logrotate.d/genieacs


```
sumber parameter : 
https://github.com/safrinnetwork/GACS-Ubuntu-22.04/tree/main || https://github.com/alijayanet/genieacs
