class hitrail {}
class hitrail::vpn {
	class { 'openswan': }

	include passwords::vpn::secrets

	openswan::connection {'hitrail': 
		type => 'tunnel',
		authby => 'secret'
		auto => 'false',
		ike => 'aes256-md5;modp1024', # The modp1024 is for Diffie-Hellman 2. Why 'modp' instead of dh? DH2 is a 1028 bit encryption algorithm that modulo's a prime number, e.g. modp1028
		esp => 'aes128-md5;modp1024' # Phase 2 (IPsec) : AES-128 MD5 3600 sec
		left => '195.177.247.117', # 1) Hit Rail - IP gateway : 195.177.247.117 (Brussels hosted Infrabel)
		leftsubnet => '172.31.255.0/30', # 1) Hit Rail - encryption domain : 172.31.255.0/30
		right => '2.139.206.217', # ASI GW
		rightsubnet => '93.94.204.248/32', # ASI - encryption domain : 93.94.204.248/32
		pfs => 'no',
		# aggrmode=no # NOTIMPLEMENTED Agressive Mode is almost never needed and 'no' is the default
	}

	openswan::shared_secret {'hitrail':
		hosts => '195.177.247.117 2.139.206.217', # leftid1 rightid1 : PSK "preshared key1"
		psk   => $passwords::vnp::secrets::hitrail,
	}
}