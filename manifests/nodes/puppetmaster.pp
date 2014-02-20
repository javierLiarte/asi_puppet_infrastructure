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
        allow_from => [
            '*.asi-soft.com',
            '*.asinet',
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