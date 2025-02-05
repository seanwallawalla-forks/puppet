# This is a role for systems which are in the process of being reclaimed
# or decommissioned. IOW. the host once had a feature role assigned, but
# currently no has it. If such hosts are simply reset to "include
# ::profile::base::production" in site.pp, they are no longer matched by role-based
# server addressing in debdeploy.
#
# This role is entirely transient. Once a system has been reclaimed to spares
# or decomissioned, this role is removed from site.pp along with the host entry.
#
class role::spare::system {
    include ::profile::base::production
    include ::profile::base::firewall

    system::role { 'spare::system': description => 'Unused spare system' }
}
