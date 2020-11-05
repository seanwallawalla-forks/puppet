# Manage unattended updates across cloud instances
#  Note: security updates can not be disabled (enabled by default)
#
# [*unattended_wmf*]
#  present/absent to enable/disable wmf packages
#
# [*unattended_distro*]
#  present/absent to enable/disable updates in stable packages

class apt::unattendedupgrades(
    $unattended_distro='present',
    $unattended_wmf='present',
    ) {

    # package installation should enable security upgrades by default
    package { 'unattended-upgrades':
        ensure => 'present',
    }

    # disable this cron job which is not useful and can produce cronspam
    file { '/etc/cron.daily/apt-show-versions':
        ensure => 'absent',
    }

    package { 'python3-apt':
        ensure => 'present',
    }

    # dpkg tries to determine the most conservative default action in case of
    # conffile conflict. This tells dpkg to use that action without asking
    apt::conf { 'dpkg-force-confdef':
        ensure   => 'present',
        priority => '00',
        key      => 'Dpkg::Options::',
        value    => '--force-confdef',
    }

    # In case of conffile conflicts, tell dpkg to keep the old conffile without
    # asking
    apt::conf { 'dpkg-force-confold':
        ensure   => 'present',
        priority => '00',
        key      => 'Dpkg::Options::',
        value    => '--force-confold',
    }

    apt::conf { 'auto-upgrades':
        ensure   => 'present',
        priority => '20',
        key      => 'APT::Periodic::Unattended-Upgrade',
        value    => '1',
    }

    # https://wiki.debian.org/StableUpdates
    # https://www.debian.org/News/2011/20110215
    apt::conf { 'unattended-upgrades-updates':
        ensure   => $unattended_distro,
        priority => '52',
        # Key with trailing '::' to append to potentially existing entry
        key      => 'Unattended-Upgrade::Origins-Pattern::',
        # lint:ignore:single_quote_string_with_variables
        value    => 'origin=${distro_id},codename=${distro_codename}-updates',
        # lint:endignore
    }

    # Unattended should update WMF packages
    # https://apt.wikimedia.org/wikimedia/
    # https://wikitech.wikimedia.org/wiki/APT_repository
    apt::conf { 'unattended-upgrades-wikimedia':
        ensure   => $unattended_wmf,
        priority => '51',
        # Key with trailing '::' to append to potentially existing entry
        key      => 'Unattended-Upgrade::Origins-Pattern::',
        # lint:ignore:single_quote_string_with_variables
        value    => 'origin=Wikimedia,codename=${distro_codename}-wikimedia',
        # lint:endignore
    }

    # Clean up the apt cache to avoid filling the disk periodically T127374
    # not using apt::conf because that changes integer values to strings    
    file { '/etc/apt/apt.conf.d/52apt-autoclean':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => 'APT::Periodic::AutocleanInterval:: 7;\n',
        notify  => Exec['apt-get update'],
    }

    file { '/usr/local/sbin/report-pending-upgrades':
        ensure => absent,
    }

    file { '/usr/local/sbin/apt-upgrade':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => 'puppet:///modules/apt/apt-upgrade.py',
        require => Package['python3-apt'],
    }
}
