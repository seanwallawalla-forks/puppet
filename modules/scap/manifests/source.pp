# == Define scap::source
#
# Sets up scap3 deployment source on a deploy server.
# This will clone $repository at /srv/deployment/$title.
# If $scap_repository is set it will clone it at
# /srv/deployment/$title/scap.  If you set $scap_repository to true,
# this will assume that your scap repository is named $title/scap.
#
# To use this in conjunction with scap::target, make sure the $title here
# matches a scap::target's $title on your target hosts, or at least matches
# the $package_name provided to scap::target (which defaults to $title).
#
# NOTE: This define is compatible with trebuchet's deployment.yaml file.
# If trebuchet has already cloned a source repository in /srv/deployment,
# this clone will do nothing, as it only executes if .git/config
# doesn't already exist.
#
# == Parameters
#
# [*repository*]
#   Repository name in gerrit/phabricator.  Default: "$title"
#
# [*scap_repository*]
#   String or boolean.
#
#   If you set this to a string, it will be assumed to be a repository name
#   This scap repository will then be cloned into /srv/deployment/$title/scap.
#   If this is set to true your scap_repository will be assumed to
#   live at $title/scap in gerrit.
#
#   You can use this keep your scap configs separate from your source
#   repositories.
#
#   Default: false.
#
# [*owner*]
#   Owner of cloned repository,
#   Default: trebuchet
#
# [*group*]
#   Group owner of cloned repository.
#   Default: wikidev
#
# [*base_path*]
#   Base path for deployments.
#   Default: /srv/deployment
#
# [*origin*]
#   Origin of cloned repository, either gerrit, phabricator or gitlab
#   Default: gerrit
#
# [*lvs_service*]
#   Name of the lvs service associated with this deployment, if any
#
# [*canaries*]
#   If this source has canary deployments, list those here
#
# [*hosts*]
#   If the software must be deployed to hosts not in a pool, add them here
#
# == Usage
#
#   # Clones the 'repo/without/external/scap' repository to
#   # /srv/deployment/repo/without/external/scap.
#
#   scap::source { 'repo/without/external/scap': }
#
#
#   # Clones the 'eventlogging' repository into
#   # /srv/deployment/eventlogging/eventbus and
#   # clones the 'eventlogging/eventbus/scap' repository
#   # into /srv/deployment/eventlogging/eventbus/scap
#
#   scap::source { 'eventlogging/eventbus':
#       repository         => 'eventlogging',
#       scap_repository    => true,
#   }
#
#
#   # Clones the 'myproject/myrepo' repository into
#   # /srv/deployment/myproject/myrepo, and
#   # clones the custom scap repository at
#   # 'my/custom/scap/repo' from gerrit into
#   # /srv/deployment/myproject/myrepo/scap
#
#   scap::source { 'myproject/myrepo':
#       scap_repository    => 'my/custom/scap/repo',
#   }
#
define scap::source(
    String $repository = $title,
    Variant[String,Boolean] $scap_repository = false,
    # TODO: change scap repo owner when scap figures out
    # how to bootstrap itself properly without trebuchet.
    String $owner                        = 'trebuchet',
    String $group                        = 'wikidev',
    Stdlib::Unixpath $base_path          = '/srv/deployment',
    String $origin                       = 'gerrit',
    Optional[Hash] $canaries             = undef,
    Optional[String] $lvs_service        = undef,
    Optional[Array[Stdlib::Fqdn]] $hosts = undef,
){

    # Checkout and prepare the scap repositories
    scap_source { $title:
        repository      => $repository,
        scap_repository => $scap_repository,
        owner           => $owner,
        group           => $group,
        base_path       => $base_path,
        origin          => $origin,
    }

    # Scap dsh lists.
    #
    # Each scap installation in production should be tied to a dsh group
    # defined via puppet.
    #
    # If you have a manual list of hosts, they should go in hiera under
    # "scap::dsh::${dsh_groupname}".
    #
    $dsh_groupname = regsubst($title, '/', '-', 'G')

    # If this deployment is linked to an lvs service, let's find out which conftool
    # cluster / service it's referring to.
    if $lvs_service {
        $service = pick(wmflib::service::fetch(true)[$lvs_service], {})
        # If we didn't find the lvs service, this will fail. It's ok, and intended
        $conftool = merge($service['lvs']['conftool'], {'datacenters' => $service['sites']})
    } else {
        $conftool = undef
    }

    if ($conftool or $hosts) {
        ::scap::dsh::group { $dsh_groupname:
            conftool => [$conftool],
            hosts    => $hosts,
        }
    }

    if ($canaries) {
        ::scap::dsh::group { "${dsh_groupname}_canaries":
            hosts => $canaries,
        }
    }
}
