# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab
#site.pp
#
# ASI Infrastructure in code with puppet
# Author 2014: Javier Liarte <jliarte@gmail.com>
#
# Contribcode from 
# - https://github.com/berndmweber/open-source-puppet-master
# - https://gerrit.wikimedia.org/r/p/operations/puppet

import "passwords.pp"

import "generic-definitions.pp"
import "profile/*.pp"



# Class for *most* servers, standard includes
class standard {
    include base
    #,
    #    ganglia,
    #    ntp::client,
    #    exim::simple-mail-sender
}

#class standard-noexim {
#    include base,
#        ganglia,
#        ntp::client
#}


# Import node definitions:
import 'nodes/*.pp'

node default {
#    include standard
}