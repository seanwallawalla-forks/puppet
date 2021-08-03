
class dragonfly::supernode {
  ensure_packages('dragonfly-supernode')

  # TODO: Add parameters for ports and cdnPatten maybe
  file { '/etc/dragonfly/supernode.yml':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('dragonfly/supernode.yml.erb'),
      notify  => Service['dragonfly-supernode'],
  }

  service { 'dragonfly-supernode':
      ensure  => running,
  }
}
