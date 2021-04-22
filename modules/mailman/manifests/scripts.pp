# helper scripts for mailman admins
class mailman::scripts {

    file { '/usr/local/sbin/remove_from_private_list':
        ensure => 'present',
        owner  => 'root',
        group  => 'list',
        mode   => '0550',
        source => 'puppet:///modules/mailman/scripts/remove_from_private.sh'
    }

    file { '/usr/local/sbin/disable_list':
        ensure => 'present',
        owner  => 'root',
        group  => 'list',
        mode   => '0550',
        source => 'puppet:///modules/mailman/scripts/disable_list.sh'
    }

    file { '/usr/local/sbin/rsync_lists':
        ensure => 'present',
        owner  => 'root',
        group  => 'list',
        mode   => '0550',
        source => 'puppet:///modules/mailman/scripts/rsync_lists.sh'
    }

    file { '/usr/local/sbin/rsync_exim':
        ensure => 'present',
        owner  => 'root',
        group  => 'list',
        mode   => '0550',
        source => 'puppet:///modules/mailman/scripts/rsync_exim.sh'
    }

    file { '/usr/local/sbin/rename_list':
        ensure => 'present',
        owner  => 'root',
        group  => 'list',
        mode   => '0550',
        source => 'puppet:///modules/mailman/scripts/rename_list.sh'
    }

    file { '/usr/local/sbin/queue_data':
        ensure => 'present',
        owner  => 'root',
        group  => 'list',
        mode   => '0550',
        source => 'puppet:///modules/mailman/scripts/queue_data.sh'
    }

    file { '/usr/local/sbin/purge_attachments':
        ensure => 'present',
        owner  => 'root',
        group  => 'list',
        mode   => '0550',
        source => 'puppet:///modules/mailman/scripts/purge_attachments.py'
    }

    file { '/usr/local/sbin/check_exclude_backups':
        ensure => 'present',
        owner  => 'root',
        group  => 'list',
        mode   => '0550',
        source => 'puppet:///modules/mailman/scripts/check_exclude_backups.py'
    }

    file { '/usr/local/sbin/list_listadmins':
        ensure => 'present',
        owner  => 'root',
        group  => 'list',
        mode   => '0550',
        source => 'puppet:///modules/mailman/scripts/list_listadmins.py'
    }
}
