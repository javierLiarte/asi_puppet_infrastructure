# modules/base/manifests/init.pp

class base::puppet($server='puppet', $certname=undef) {

    include passwords::puppet::database

    ## run puppet by cron and
    ## rotate puppet logs generated by cron
    ## This is in mins. Do not set this to 0 or > 60
    $interval = 30
    $crontime = fqdn_rand(60)
    # Calculate freshness interval in seconds (hence *60)
    $freshnessinterval = $interval * 60 * 6

    package { [ 'puppet', 'facter', 'coreutils' ]:
        ensure => latest,
    }

    if $::lsbdistid == 'Ubuntu' and (versioncmp($::lsbdistrelease, '10.04') == 0 or versioncmp($::lsbdistrelease, '8.04') == 0) {
        package {'timeout':
            ensure => latest,
        }
    }

#    # monitoring via snmp traps
#    package { 'snmp':
#        ensure => latest,
#    }
#
#    file { '/etc/snmp':
#        ensure  => directory,
#        owner   => 'root',
#        group   => 'root',
#        mode    => '0644',
#        require => Package['snmp'],
#    }
#
#    file { '/etc/snmp/snmp.conf':
#        ensure  => present,
#        owner   => 'root',
#        group   => 'root',
#        mode    => '0444',
#        content => template('base/snmp.conf.erb'),
#        require => [ Package['snmp'], File['/etc/snmp'] ],
#    }

#   This is for nagios monitoring, defined in modules/nrpe/manifests/monitor_service.pp
#    monitor_service { 'puppet freshness':
#        description     => 'Puppet freshness',
#        check_command   => 'puppet-FAIL',
#        passive         => 'true',
#        freshness       => $freshnessinterval,
#        retries         => 1,
#    }

#   This is again for SNMP monitoring -- snmptrap: sends an SNMP notification to a manager
#    case $::realm {
#        'production': {
#            exec {  'neon puppet snmp trap':
#                command => "snmptrap -v 1 -c public neon.wikimedia.org .1.3.6.1.4.1.33298 `hostname` 6 1004 `uptime | awk '{ split(\$3,a,\":\"); print (a[1]*60+a[2])*60 }'`",
#                path    => '/bin:/usr/bin',
#                require => Package['snmp'],
#            }
#        }
#        'labs': {
#            # The next two notifications are read in by the labsstatus.rb puppet report handler.
#            #  It needs to know project/hostname for nova access.
#            notify{"instanceproject: ${::instanceproject}":}
#            notify{"hostname: ${::instancename}":}
#            exec { 'puppet snmp trap':
#                command => "snmptrap -v 1 -c public icinga.pmtpa.wmflabs .1.3.6.1.4.1.33298 ${::instancename}.${::site}.wmflabs 6 1004 `uptime | awk '{ split(\$3,a,\":\"); print (a[1]*60+a[2])*60 }'`",
#                path    => '/bin:/usr/bin',
#                require => Package['snmp'],
#            }
#        }
#        default: {
#            err('realm must be either "labs" or "production".')
#        }
#    }

    file { '/etc/default/puppet':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/base/puppet/puppet.default',
    }

    file { '/etc/puppet/puppet.conf':
        ensure => 'file',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        notify => Exec['compile puppet.conf'],
    }

    file { '/etc/puppet/puppet.conf.d/':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
    }

    file { '/etc/puppet/puppet.conf.d/10-main.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('base/puppet.conf.d/10-main.conf.erb'),
        notify  => Exec['compile puppet.conf'],
    }

    file { '/etc/init.d/puppet':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/base/puppet/puppet.init',
    }

#   TODO: explore what is this
#    class { 'puppet_statsd':
#        statsd_host   => 'statsd.eqiad.wmnet',
#        metric_format => 'puppet.<%= metric %>',
#    }

    # Compile /etc/puppet/puppet.conf from individual files in /etc/puppet/puppet.conf.d
    exec { 'compile puppet.conf':
        path        => '/usr/bin:/bin',
        command     => "cat /etc/puppet/puppet.conf.d/??-*.conf > /etc/puppet/puppet.conf",
        refreshonly => true,
    }

    # Keep puppet running -- no longer. now via cron
    cron { 'restartpuppet':
        ensure  => absent,
        require => File['/etc/default/puppet'],
        command => '/etc/init.d/puppet restart > /dev/null',
        user    => 'root',
        # Restart every 4 hours to avoid the runs bunching up and causing an
        # overload of the master every 40 mins. This can be reverted back to a
        # daily restart after we switch to puppet 2.7.14+ since that version
        # uses a scheduling algorithm which should be more resistant to
        # bunching.
        hour    => [0, 4, 8, 12, 16, 20],
        minute  => '37',
    }

    cron { 'remove-old-lockfile':
        ensure  => absent,
        require => Package['puppet'],
        command => "[ -f /var/lib/puppet/state/puppetdlock ] && find /var/lib/puppet/state/puppetdlock -ctime +1 -delete",
        user    => 'root',
        minute  => '43',
    }

    ## do not use puppet agent
    service {'puppet':
        ensure => stopped,
        enable => false,
    }

    file { '/etc/cron.d/puppet':
        require => File['/etc/default/puppet'],
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('base/puppet.cron.erb'),
    }

    file { '/etc/logrotate.d/puppet':
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/base/logrotate/puppet',
    }

    # Report the last puppet run in MOTD
    if $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '9.10') >= 0 {
        file { '/etc/update-motd.d/97-last-puppet-run':
            owner   => 'root',
            group   => 'root',
            mode    => '0555',
            source  => 'puppet:///modules/base/puppet/97-last-puppet-run',
        }
    }
}


class base {

#    include apt
#    include apt::update
#
#    if ($::realm == 'labs') {
#        include apt::unattendedupgrades,
#            apt::noupgrade
#    }
#
#    include base::tcptweaks

    file { '/usr/local/sbin':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    class { 'base::puppet':
        server => $::realm ? {
            'labs' => $::site ? {
                'pmtpa' => 'virt0.wikimedia.org',
                'eqiad' => 'virt1000.wikimedia.org',
            },
            default => 'puppetmaster',
        },
        certname => $::realm ? {
            # For labs, use instanceid.domain rather than the fqdn
            # to ensure we're always using a unique certname.
            # dc is an attribute from LDAP, it's set as the instanceid.
            'labs'  => $::dc,
            default => undef,
        },
    }

    include passwords::root,
        base::cron,
#        base::decommissioned,
#        base::grub,
#        base::resolving,
#        base::remote-syslog,
#        base::sysctl,
#        base::motd,
#        base::vimconfig,
#        base::standard-packages,
#        base::environment,
#        base::platform,
#        base::access::dc-techs,
#        base::screenconfig,
        ssh::client,
        ssh::server
#        role::salt::minions


    # include base::monitor::host.
    # if $nagios_contact_group is set, then use it
    # as the monitor host's contact group.
#    class { 'base::monitoring::host':
#        contact_group => $::nagios_contact_group ? {
#            undef     => 'admins',
#            default   => $::nagios_contact_group,
#        }
#    }

    if $::realm == 'labs' {
        include base::instance-upstarts,
            gluster::client

        # Storage backend to use for /home & /data/project
        # Configured on a per project basis inside puppet since we do not have any
        # other good way to do so yet.
        # FIXME  this is ugly and need to be removed whenever we got rid of
        # the Gluster shared storage.
        if $::instanceproject == 'deployment-prep' {
                include role::labsnfs::client
        }

        # make common logs readable
        class {'base::syslogs': readable => true }

        # Add directory for data automounts
        file { '/data':
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }
        # Add directory for public (ro) automounts
        file { '/public':
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }
    }
}
