class openstack::puppet::master::enc(
    $puppetmaster,
    ) {

    ensure_packages(['python3-yaml', 'python3-ldap3'])

    include ldap::yamlcreds

    file { '/etc/puppet-enc.yaml':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => ordered_yaml({
            host => $puppetmaster,
        }),
    }

    file { '/usr/local/bin/puppet-enc':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/openstack/puppet/master/labs-puppet-enc.py',
    }
}
