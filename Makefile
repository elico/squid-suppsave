
all:
	echo "1"

reload: collect-whitelist collect-blacklist collect-ssl-bump collect-no-ssl-bump collect-block-connect-dst
	systemctl reload squid

reload-with-db: dump-db-no-bump dump-db-bump dump-db-youtube collect-whitelist collect-blacklist collect-ssl-bump collect-no-ssl-bump collect-block-connect-dst
	systemctl reload squid

collect-ssl-bump:
	cat ssl-bump/*.regex |tee ssl-bump-regex.list.in >/dev/null
	mv ssl-bump-regex.list.in ssl-bump-regex.list
	
	cat ssl-bump/*.server-name |tee ssl-bump-server-name.list.in >/dev/null
	cat ssl-bump-server-name.list.in |sort|uniq |tee ssl-bump-server-name.list.in-sorted >/dev/null
	mv ssl-bump-server-name.list.in-sorted ssl-bump-server-name.list
	
	cat ssl-bump/*.addresses |tee /etc/squid/ssl-bump-server-dst-addresses.list.in >/dev/null
	mv ssl-bump-server-dst-addresses.list.in ssl-bump-server-dst-addresses.list
	
	find ssl-bump/*.urls | xargs -l1 -n1 -I{} scripts/urls-to-bump-domains-regex.rb {} |tee ssl-bump-urls-domains-regex.list.in >/dev/null
	mv ssl-bump-urls-domains-regex.list.in ssl-bump-urls-domains-regex.list

collect-no-ssl-bump:
	cat no-ssl-bump/*.regex |tee no-ssl-bump-regex.list.in >/dev/null
	mv no-ssl-bump-regex.list.in no-ssl-bump-regex.list
	
	cat no-ssl-bump/*.server-name |tee no-ssl-bump-server-name.list.in >/dev/null
	cat no-ssl-bump-server-name.list.in |sort|uniq |tee no-ssl-bump-server-name.list.in-sorted >/dev/null
	mv no-ssl-bump-server-name.list.in-sorted no-ssl-bump-server-name.list
	
	cat no-ssl-bump/*.addresses |tee no-ssl-bump-server-dst-addresses.list.in >/dev/null
	mv no-ssl-bump-server-dst-addresses.list.in no-ssl-bump-server-dst-addresses.list
	
	cat no-ssl-bump/*.src |tee no-ssl-bump-client-src.list.in >/dev/null
	mv no-ssl-bump-client-src.list.in no-ssl-bump-client-src.list
	
	find no-ssl-bump/*.urls | xargs -l1 -n1 -I{} scripts/urls-to-bump-domains-regex.rb {} |tee no-ssl-bump-urls-domains-regex.list.in >/dev/null
	mv no-ssl-bump-urls-domains-regex.list.in no-ssl-bump-urls-domains-regex.list
	
	find no-ssl-bump/*.cert-fingerprint | xargs -l1 -n1 -I{} scripts/sha1-fingerprint-to-file.rb {} |tee no-ssl-bump-server-fingerprint.list.in >/dev/null
	mv no-ssl-bump-server-fingerprint.list.in no-ssl-bump-server-fingerprint.list

collect-block-connect-dst:
	cat block-connect-dests/*.dst |tee blocked-connect-dests-dst.list.in >/dev/null
	mv blocked-connect-dests-dst.list.in blocked-connect-dests-dst.list

clean-squid-conf:
	cd /etc/squid && egrep -v "(^#|^$$)" squid.conf | tee squid.conf.clean >/dev/null

support-save: clean-squid-conf collect-machine-info
	squid -v | tee /etc/squid/version
	cd /etc && tar --exclude='squid/ssl_cert' -zcf ../support-save-$(shell date +%Y-%m-%d_%H-%M-%S).tar.gz squid

collect-machine-info:
	bin/collect-machine-info.sh 2>&1 | tee /etc/squid/machine-info

collect-blacklist:
	find blacklist/*.urls |xargs -l1 -n1 -I{}  scripts/urls-to-regex.rb {} |tee urls-blacklist-regex.list.in >/dev/null
	mv urls-blacklist-regex.list.in urls-blacklist-regex.list
	
	find blacklist/*.yt-vids |xargs -l1 -n1 -I{}  scripts/yt-vids-to-regex.rb {} |tee yt-urls-blacklist-regex.list.in >/dev/null
	mv yt-urls-blacklist-regex.list.in yt-urls-blacklist-regex.list
	
	cat blacklist/*.regex |tee regex-blacklist.list.in >/dev/null
	mv regex-blacklist.list.in regex-blacklist.list

collect-whitelist:
	find whitelist/*.urls |xargs -l1 -n1 -I{}  scripts/urls-to-regex.rb {} |tee urls-whitelist-regex.list.in >/dev/null
	mv urls-whitelist-regex.list.in urls-whitelist-regex.list
		
	find whitelist/*.yt-vids |xargs -l1 -n1 -I{}  scripts/yt-vids-to-regex.rb {} |tee yt-urls-whitelist-regex.list.in >/dev/null
	mv yt-urls-whitelist-regex.list.in yt-urls-whitelist-regex.list
	
	cat whitelist/*.regex |tee regex-whitelist.list.in >/dev/null
	mv regex-whitelist.list.in regex-whitelist.list

splice-all:
	echo ".*" |tee no-ssl-bump/099-catch-all.regex
	touch ssl-bump/099-catch-all.regex
	rm -vf ssl-bump/099-catch-all.regex

bump-all:
	echo ".*" |tee no-ssl-bump/099-catch-all.regex
	touch no-ssl-bump/099-catch-all.regex
	rm -vf no-ssl-bump/099-catch-all.regex

dump-db-bump: dump-db-bump-domains dump-db-bump-regex dump-db-bump-addresses dump-db-bump-urls

dump-db-bump-domains:
	mysql -s -r -N  -u filter -pfilter squid_conf -e "SELECT value FROM bump_domains;" |tee ssl-bump/080-filter-db.server-name >/dev/null

dump-db-bump-regex:
	mysql -s -r -N  -u filter -pfilter squid_conf -e "SELECT value FROM bump_regex;" |tee ssl-bump/080-filter-db.regex >/dev/null

dump-db-bump-addresses:
	mysql -s -r -N  -u filter -pfilter squid_conf -e "SELECT value FROM bump_ip_addresses;" |tee ssl-bump/080-filter-db.addresses >/dev/null

dump-db-bump-urls:
	mysql -s -r -N  -u filter -pfilter squid_conf -e "SELECT value FROM bump_urls;" |tee ssl-bump/080-filter-db.urls >/dev/null


dump-db-no-bump: dump-db-no-bump-domains dump-db-no-bump-regex dump-db-no-bump-addresses dump-db-no-bump-urls dump-db-no-bump-certificate-fingerprint

dump-db-no-bump-domains:
	mysql -s -r -N  -u filter -pfilter squid_conf -e "SELECT value FROM splice_domains;" |tee no-ssl-bump/080-filter-db.server-name >/dev/null

dump-db-no-bump-regex:
	mysql -s -r -N  -u filter -pfilter squid_conf -e "SELECT value FROM splice_regex;" |tee no-ssl-bump/080-filter-db.regex >/dev/null

dump-db-no-bump-addresses:
	mysql -s -r -N  -u filter -pfilter squid_conf -e "SELECT value FROM splice_ip_addresses;" |tee no-ssl-bump/080-filter-db.addresses >/dev/null

dump-db-no-bump-urls:
	mysql -s -r -N  -u filter -pfilter squid_conf -e "SELECT value FROM splice_urls;" |tee no-ssl-bump/080-filter-db.urls >/dev/null

dump-db-no-bump-certificate-fingerprint:
	mysql -s -r -N  -u filter -pfilter squid_conf -e "SELECT value FROM splice_server_certificate_by_hash;" |tee no-ssl-bump/020-cert-filter-db.cert-fingerprint >/dev/null

dump-db-youtube: dump-db-youtube-whitelist dump-db-youtube-blacklist

dump-db-youtube-whitelist:
	mysql -s -r -N  -u filter -pfilter squid_conf -e "SELECT value FROM youtube_whitelist;" |tee whitelist/040-db-whitelist.yt-vids >/dev/null

dump-db-youtube-blacklist:
	mysql -s -r -N  -u filter -pfilter squid_conf -e "SELECT value FROM youtube_blacklist;" |tee blacklist/040-db-blacklist.yt-vids >/dev/null

install-external-ca-certificates:
	mkdir -p /etc/pki/ca-trust/source/anchors/
	cat external-certs/*.pem > /etc/pki/ca-trust/source/anchors/squid-anchors.pem
	update-ca-trust extract
	# Should update: /etc/pki/tls/certs/ca-bundle.crt

amzn2-install-suppsave-deps:
	yum install -y lshw lsscsi
	
