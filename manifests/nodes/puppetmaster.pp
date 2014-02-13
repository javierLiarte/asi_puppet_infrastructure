node 'palladium.eqiad.wmnet' {
    include passwords::puppet::database

    include standard,
        backup::client,
        misc::management::ipmi,
        role::salt::masters::production,
        role::deployment::salt_masters::production

    class { puppetmaster:
        allow_from => [
            '*.wikimedia.org',
            '*.pmtpa.wmnet',
            '*.eqiad.wmnet',
            '*.ulsfo.wmnet',
         ],
        server_type => 'frontend',
        workers => ['palladium.eqiad.wmnet', 'strontium.eqiad.wmnet'],
        config => {
            'thin_storeconfigs' => true,
            'dbadapter' => 'mysql',
            'dbuser' => 'puppet',
            'dbpassword' => $passwords::puppet::database::puppet_production_db_pass,
            'dbserver' => 'db1001.eqiad.wmnet',
        }
    }
}