class profile::openstack::codfw1dev::nova::conductor::service(
    $version = hiera('profile::openstack::codfw1dev::version'),
    ) {

    require ::profile::openstack::codfw1dev::nova::common
    class {'::profile::openstack::base::nova::conductor::service':
        version         => $version,
    }
}
