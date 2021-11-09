class ceph::auth::deploy (
    Hash             $configuration,
    Array[String[1]] $selected_creds,
) {
    $configuration.each |String $client_name, Ceph::Auth::ClientAuth $client_auth| {
        if ($client_name in $selected_creds) {
            $keyring_path = pick($client_auth['keyring_path'], "/etc/ceph/ceph.client.${client_name}.keyring")
            ceph::auth::keyring { $client_name:
                keyring_path   => $keyring_path,
                keydata        => $client_auth['keydata'],
                import_to_ceph => false,
                caps           => $client_auth['caps'],
            }
        }
    }
}
