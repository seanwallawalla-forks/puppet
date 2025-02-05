class profile::openstack::base::networktests (
    String[1]           $region                = lookup('porfile::openstack::base::region'),
    Stdlib::Fqdn        $sshbastion            = lookup('profile::openstack::base::networktests::sshbastion'),
    Hash                $envvars               = lookup('profile::openstack::base::networktests::envvars'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::base::openstack_controllers'),
) {
    class { 'openstack::monitor::networktests':
        timer_active => ($::fqdn == $openstack_controllers[1]), # not [0] because decoupling
        region       => $region,
        sshbastion   => $sshbastion,
        envvars      => $envvars,
    }
}
