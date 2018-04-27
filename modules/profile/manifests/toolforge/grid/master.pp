# Establish the gridengine master role (one per cluster)

class profile::toolforge::grid::master (
    $etcdir = hiera('profile::toolforge::etcdir'),
){
    # include ::toollabs::queue::continuous
    # include ::toollabs::queue::task
    class { '::sonofgridengine::master':
        etcdir  => $etcdir,
    }

    gridengine_complex { 'h_vmem':
        ensure      => present,
        shortcut    => 'h_vmem',
        type        => 'MEMORY',
        relop       => '<=',
        requestable => 'FORCED',
        default     => '0',
        urgency     => '0',
        consumable  => 'YES',
        require     => Service['gridengine-master'],
    }

    gridengine_complex { 'release':
        ensure      => present,
        shortcut    => 'rel',
        type        => 'CSTRING',
        relop       => '==',
        requestable => 'YES',
        consumable  => 'NO',
        default     => 'NONE',
        urgency     => '0',
        require     => Service['gridengine-master'],
    }

    gridengine_complex { 'user_slot':
        ensure      => present,
        shortcut    => 'u',
        type        => 'INT',
        relop       => '<=',
        requestable => 'YES',
        consumable  => 'YES',
        default     => '0',
        urgency     => '0',
        require     => Service['gridengine-master'],
    }

    file { "${toolforge::collectors}/hostgroups":
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { "${toollabs::collectors}/queues":
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    sonofgridengine::collectors::hostgroups { '@general':
        store => "${toollabs::collectors}/hostgroups",
    }

    sonofgridengine::collectors::queues { 'webgrid-lighttpd':
        store  => "${toollabs::collectors}/queues",
        config => 'toollabs/gridengine/queue-webgrid.erb',
    }

    sonofgridengine::collectors::queues { 'webgrid-generic':
        store  => "${toollabs::collectors}/queues",
        config => 'toollabs/gridengine/queue-webgrid.erb',
    }

    #
    # These things are done on toollabs::master because they
    # need to be done exactly once per project (they live on the
    # shared filesystem), and there can only be exactly one
    # gridmaster in this setup.  They could have been done on
    # any singleton instance.
    #

    # Make sure that old-style fqdn for nodes are still understood
    # in this new-style fqdn environment by making aliases for the
    # nodes that existed before the change:
    # file { '/var/lib/gridengine/default/common/host_aliases':
    #     ensure  => file,
    #     owner   => 'root',
    #     group   => 'root',
    #     mode    => '0444',
    #     source  => 'puppet:///modules/toollabs/host_aliases',
    #     require => File['/var/lib/gridengine'],
    # }

    file { '/usr/local/bin/dequeugridnodes.sh':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/toolforge/gridscripts/dequeuegridnodes.sh',
    }
    file { '/usr/local/bin/requeugridnodes.sh':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/toolforge/gridscripts/requeuegridnodes.sh',
    }
    file { '/usr/local/bin/runninggridtasks.py':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/toolforge/gridscripts/runninggridtasks.py',
    }
    file { '/usr/local/bin/runninggridjobsmail.py':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/toolforge/gridscripts/runninggridjobsmail.py',
    }

    file { "${profile::toolforge::grid::base::geconf}/spool":
        ensure  => directory,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        require => File[$toolforge::geconf],
    }

    file { '/var/spool/gridengine':
        ensure  => link,
        target  => "${profile::toolforge::grid::base::geconf}/spool",
        force   => true,
        require => File["${profile::toolforge::grid::base::geconf}/spool"],
    }
}
