# This defines the actual nginx daemon/instance which tlsproxy "sites" belong to
class profile::tlsproxy::instance(
    Boolean $bootstrap_protection                           = lookup('profile::tlsproxy::instance::bootstrap_protection'),
    Boolean $nginx_ssl_dyn_rec                              = lookup('profile::tlsproxy::instance::nginx_ssl_dyn_rec'),
    Boolean $nginx_tune_for_media                           = lookup('profile::tlsproxy::instance::nginx_tune_for_media'),
    String $nginx_client_max_body_size                      = lookup('profile::tlsproxy::instance::nginx_client_max_body_size'),
    Enum['full', 'extras', 'light'] $nginx_variant          = lookup('profile::tlsproxy::instance::nginx_variant'),
    Enum['strong', 'mid', 'compat'] $ssl_compatibility_mode = lookup('profile::tlsproxy::instance::ssl_compatibility_mode'),
){
    # Enable client/server TCP Fast Open (TFO)
    require ::profile::tcp_fast_open

    $nginx_worker_connections = '131072'
    $nginx_ssl_conf = ssl_ciphersuite('nginx', $ssl_compatibility_mode)

    # If numa_networking is turned on, use interface_primary for NUMA hinting,
    # otherwise use 'lo' for this purpose.  Assumes NUMA data has "lo" interface
    # mapped to all cpu cores in the non-NUMA case.  The numa_iface variable is
    # in turn consumed by the systemd unit and config templates.
    if $::numa_networking != 'off' {
        $numa_iface = $facts['interface_primary']
    } else {
        $numa_iface = 'lo'
    }

    # If nginx will be installed on a system where apache is already
    # running, the postinst script will fail to start it with the default
    # configuration as port 80 is already in use. This is considered working
    # as designed by Debian, see
    #    https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=754407
    # However, we need the installation to complete correctly for puppet to
    # work as expected, hence we pre-install a configuration that will make
    # that possible. Note this file will be overwritten by puppet when
    # the nginx configuration gets installed properly.
    if $bootstrap_protection {
        exec { 'Dummy nginx.conf for installation':
            command => '/bin/mkdir -p /etc/nginx && /bin/echo -e "events { worker_connections 1; }\nhttp{ server{ listen 666; }}\n" > /etc/nginx/nginx.conf',
            creates => '/etc/nginx/nginx.conf',
            before  => Class['nginx'],
        }
    }

    # Make sure nginx.service is not automatically started upon package install
    systemd::mask { 'nginx.service':
        unless => "/usr/bin/dpkg -s nginx-${nginx_variant} | /bin/grep -q '^Status: install ok installed$'",
    }

    systemd::unmask { 'nginx.service': }

    # Ensure systemctl mask happens before the package is installed, and that
    # package installation triggers service unmask
    Systemd::Mask['nginx.service'] -> Package["nginx-${nginx_variant}"] ~> Systemd::Unmask['nginx.service']

    class { 'nginx':
        variant => $nginx_variant,
        managed => false,
    }

    file { '/etc/nginx/nginx.conf':
        content => template('profile/tlsproxy/nginx.conf.erb'),
        tag     => 'nginx',
    }

    logrotate::conf { 'nginx':
        ensure => present,
        source => 'puppet:///modules/profile/tlsproxy/logrotate',
        tag    => 'nginx',
    }

    # systemd unit fragments for NUMA and security
    $sysd_nginx_dir = '/etc/systemd/system/nginx.service.d'
    $sysd_numa_conf = "${sysd_nginx_dir}/numa.conf"
    $sysd_sec_conf = "${sysd_nginx_dir}/security.conf"

    file { $sysd_nginx_dir:
        ensure => directory,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    file { $sysd_numa_conf:
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('profile/tlsproxy/nginx-numa.conf.erb'),
        before  => Class['nginx'],
        require => File[$sysd_nginx_dir],
    }

    file { $sysd_sec_conf:
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/profile/tlsproxy/nginx-security.conf',
        before  => Class['nginx'],
        require => File[$sysd_nginx_dir],
    }

    exec { 'systemd reload for nginx systemd fragments':
        refreshonly => true,
        command     => '/bin/systemctl daemon-reload',
        subscribe   => [File[$sysd_numa_conf],File[$sysd_sec_conf]],
    }
}
