# modules/base/manifests/cron.php
#
# Base module manifest for cron service

class base::cron {
	   package { "cron":
	    ensure => installed,
	  }
}