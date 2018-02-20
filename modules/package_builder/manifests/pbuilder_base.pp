# == Definition pbuilder_base
#
# Parameters:
#
# [*mirror*]
# Apt mirror to bootstrap the image from.
# Default: 'http://mirrors.wikimedia.org/debian
#
# [*distribution*]
# Target Distribution (e.g: trusty, jessie, stretch, etc)
# Default: 'stretch'
#
# [*components*]
# List of distribution components to install. Passed as is to pbuilder, space
# separated.
# Default: 'main'
#
# [*architecture*]
# Target architecture (e.g: i386, amd64).
# Default: 'amd64'
#
# [*basepath*]
# Directory that holds the cow images.
# Default: '/var/cache/pbuilder'
#
# [*keyring*]
# Path to an additional keyring to use. Passed to debootstrap --keyring option.
# Example: '/usr/share/keyrings/debian-archive-keyring.gpg'.
# Default: undef
#
# [*distribution_alias*]
# Alias for the distribution. Will create a symbolic link, that is merely a
# workaround to recognize both 'sid' and 'unstable' while generating only a
# single cow image.
# Default: undef
define package_builder::pbuilder_base(
    $mirror='http://mirrors.wikimedia.org/debian',
    $distribution='stretch',
    $distribution_alias=undef,
    $components='main',
    $architecture='amd64',
    $basepath='/var/cache/pbuilder',
    $keyring=undef,
) {
    if $keyring {
        $arg = "--debootstrapopts --keyring=${keyring}"
    } else {
        $arg = ''
    }

    $cowdir = "${basepath}/base-${distribution}-${architecture}.cow"

    # We need to be explicit with specifying only released distros since the
    # other chroots supported (like unstable) are not present on security.debian.org
    if ($distribution == 'stretch' or $distribution == 'jessie' or $distribution == 'buster') {
        $security_apt = "--othermirror \"deb http://security.debian.org/ ${distribution}/updates ${components}\""
    } else {
        $security_apt = ''
    }

    $command = "/usr/sbin/cowbuilder --create \
                        --mirror ${mirror} \
                        --distribution ${distribution} \
                        --components \"${components}\" \
                        --architecture ${architecture} \
                        --basepath \"${cowdir}\" \
                        --debootstrapopts --variant=buildd \
                        ${security_apt} ${arg}"

    exec { "cowbuilder_init_${distribution}-${architecture}":
        command => $command,
        creates => $cowdir,
    }

    $update_command = "/usr/sbin/cowbuilder --update --override-config \
                    --basepath \"${cowdir}\" \
                    ${security_apt} \
                    >/dev/null 2>&1"

    cron { "cowbuilder_update_${distribution}-${architecture}":
        command     => $update_command,
        environment => ['PATH=/usr/bin:/bin:/usr/sbin'],
        hour        => 7,
        minute      => 34,
    }

    if $distribution_alias {
        file { "${basepath}/base-${distribution_alias}-${architecture}.cow":
            ensure => link,
            target => $cowdir,
        }
    }
}
