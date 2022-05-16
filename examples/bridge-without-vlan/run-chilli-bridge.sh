cp wireless /etc/config/wireless
cp network /etc/config/network
cp firewall /etc/config/firewall
cp defaults /etc/chilli/defaults
cp indiochilli /etc/config/indiochilli
cp firewall.user /etc/firewall.user
uci set firewall.@zone[0].masq='0'
uci commit firewall
wifi
