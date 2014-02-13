node 'puppetmaster.asinet' {
    include passwords::puppet::database

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
            'dbserver' => 'db1001.wmnet',
        }
    }
}