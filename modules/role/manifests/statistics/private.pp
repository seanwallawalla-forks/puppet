class role::statistics::private {
    system::role { 'statistics::private':
        description => 'Statistics private data host and general compute node'
    }

    include ::profile::standard

    include ::profile::analytics::cluster::gitconfig

    include ::profile::statistics::private

    # Run Hadoop/Hive reportupdater jobs here.
    include ::profile::reportupdater::jobs::hadoop

    # This job copies wiktext dumps from the NFS mounts to HDFS
    include ::profile::analytics::refinery::job::import_wikitext_dumps

    # Systemd timers owned by the Search team
    # (leveraging Analytics' refinery)
    include ::profile::analytics::search::jobs

    # Include Hadoop and other analytics cluster
    # clients so that analysts can access Hadoop
    # from here.
    include ::profile::analytics::cluster::client

    include ::profile::analytics::cluster::packages::hadoop

    # Include analytics/refinery deployment target.
    include ::profile::analytics::refinery

    # This is a Hadoop client, and should
    # have any special analytics system users on it
    # for interacting with HDFS.
    include ::profile::analytics::cluster::users

    # Set up a read only rsync module to allow access
    # to public data generated by the Analytics Cluster.
    include ::profile::analytics::cluster::rsyncd

    # Deploy wikimedia/discovery/analytics repository
    # to this node.
    include ::profile::analytics::cluster::elasticsearch

    # Deploy performance/asoranking repository
    # to this node.
    include ::profile::analytics::asoranking
}
