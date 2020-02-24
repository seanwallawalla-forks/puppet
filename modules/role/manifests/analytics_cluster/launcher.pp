# == Class role::analytics_cluster::launcher
#
class role::analytics_cluster::launcher {

    system::role { 'analytics_cluster::launcher':
        description => 'Analytics Cluster host running periodical jobs (Hadoop, Report Updater, etc..)'
    }

    include ::profile::analytics::cluster::client

    # This is a Hadoop client, and should
    # have any special analytics system users on it
    # for interacting with HDFS.
    include ::profile::analytics::cluster::users

    include ::profile::hive::site_hdfs

    include ::profile::analytics::cluster::gitconfig

    # Include analytics/refinery deployment target.
    include ::profile::analytics::refinery

    include ::profile::kerberos::client
    include ::profile::kerberos::keytabs

    include ::profile::standard
    include ::profile::base::firewall
}