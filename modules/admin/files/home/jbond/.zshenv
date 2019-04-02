alias ls='ls --color=auto'
alias grep='grep --color=auto'
if [[ $(hostname -f) = install*wikimedia* ]]; then
    export REPREPRO_BASE_DIR=/srv/wikimedia
    export GNUPGHOME=/root/.gnupg
fi
PROXY=http://webproxy:8080
export http_proxy=${PROXY}
export HTTP_PROXY=${PROXY}
export https_proxy=${PROXY}
export HTTPS_PROXY=${PROXY}
export EDITOR=vim
export DEBEMAIL=jbond@wikimedia.org
export DEBFULLNAME="John Bond"
