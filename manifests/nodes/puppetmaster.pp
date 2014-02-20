node 'puppetmaster.asi-soft.com' {
    include passwords::puppet::database

    include standard

    class { '::mysql::server':
        root_password => $passwords::mysql::root_pwd,
        override_options => { 
            'mysqld' => { 
                'max_connections' => '600',
                'query_cache_size' => '64M'
            }
        }
    }
    class { puppetmaster:
        server_name => 'puppetmaster',
        allow_from => [
            '*.asi-soft.com',
            '*.asinet',
            '192.168.1.0/24',
            '10.2.4.0/24'
         ],
        server_type => 'standalone',
        config => {
            'thin_storeconfigs' => true, # only collects and stores to the database exported resources, tags and host facts
            'dbadapter' => 'mysql',
            'dbuser' => 'puppet',
            'dbpassword' => $passwords::puppet::database::puppet_production_db_pass,
            'dbserver' => 'puppetmaster.asinet',
        }
    }
}