# modules/base/manifests/cron.php
#
# Base module manifest for cron service

class cron {
	   package { "cron":
	    ensure => installed,
	  }
}