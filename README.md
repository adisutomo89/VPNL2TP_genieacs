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
```
```bash
sudo nano /etc/ppp/ip-up
# Route otomatis untuk PPP L2TP
if [ "$PPP_IFACE" = "ppp0" ]; then
    ip route add 12.5.89.0/24 dev ppp0 || true
fi
```

Mikrotik
```bash
/interface list
add name=PPPOE comment="List untuk semua PPPoE client"

/system scheduler
add name=AutoPPPoEtoList interval=1m on-event="/interface list member remove [find list=PPPOE]; :foreach i in=[/interface find where type~\"pppoe\"] do={/interface list member add list=PPPOE interface=\$i}" comment="Otomatis masukkan semua PPPoE ke list"
```
sumber parameter : 
https://github.com/safrinnetwork/GACS-Ubuntu-22.04/tree/main
https://github.com/alijayanet/genieacs
