# @summary
#   Configure envoy to be a TLS proxy to local services.
#   It's thought as a simple shoe-in replacement for tlsproxy::localssl
#   in limited use-cases for internal usage.
#   The port on which Envoy should listen must be specified in the title.
#
# @example Set up a simple TLS termination for an upstream serving on port 80
#   envoyproxy::tls_terminator { '443':
#     upstreams => [{
#       server_names => ['citoid.svc.eqiad.wmnet', 'citoid'],
#       cert_path    => '/etc/ssl/localcerts/citoid.crt',
#       key_path     => '/etc/ssl/localcerts/citoid.key',
#       upstream_port => 1234
#     },
#     {
#       server_names => ['pdfrenderer.svc.eqiad.wmnet', 'pdfrenderer'],
#       cert_path    => '/etc/ssl/localcerts/evil.crt',
#       key_path     => '/etc/ssl/localcerts/evil.key',
#       upstream_port => 666
#     }],
#     connect_timeout => 0.25,
#     global_cert_path => '/etc/ssl/localcerts/services.crt',
#     global_cert_key  => '/etc/ssl/localcert/services.key'
#   }
#
# @example Set up non-sni only termination to backends, listen on TCP port 444
#   envoyproxy::tls_terminator { '444':
#     upstreams => [{
#       server_names => ['citoid.svc.eqiad.wmnet', 'citoid'],
#       upstream_port => 1234
#     },
#     {
#       server_names => ['pdfrenderer.svc.eqiad.wmnet', 'pdfrenderer'],
#       upstream_port => 666
#     }],
#     connect_timeout => 0.25,
#     global_cert_path => '/etc/ssl/localcerts/services.crt',
#     global_cert_key  => '/etc/ssl/localcert/services.key'
#   }
# @example Set up TLS global proxying in front of apache
#   envoyproxy::tls_terminator { '443':
#     upstreams => [{
#       server_names => ['*'],
#       upstream_port => 80B
#     },
#     connect_timeout => 0.25,
#     global_cert_path => '/etc/ssl/localcerts/services.crt',
#     global_cert_key  => '/etc/ssl/localcert/services.key'
#   }
#
# @param upstreams
#   A list of Envoyproxy::Tlsconfig structures defining the upstream
#   server configurations. A non-SNI default catchall will be autogenerated.
# @param redir_port
#     TCP port to listen on as plain HTTP.  This listener will redirect
#     GET/HEAD to HTTPS with 301 and deny all other methods with 403.  It does
#     not proxy any traffic. If undefined, no HTTP redirect will be created.
#     Default is undefined.
# @param access_log
#     If true, sets up the access log for the TLS terminator.
# @param websockets
#     If true, allows websocket upgrades.
# @param use_remote_address
#     If true append the client IP to the x-forwarded-for header
# @param fast_open_queue
#     The size of the fast open queue. If zero, TFO is disabled.
# @param connect_timeout
#     The time is seconds to wait before declaring a connection timeout to the
#     upstream resource
# @param listen_ipv6
#     Listen on IPv6 adding ipv4_compat  allow both IPv4 and IPv6 connections,
#     with peer IPv4 addresses mapped into IPv6 space as ::FFFF:<IPv4-address>
# @param retry_policy
#     An optional hash specifying the retry policy. It should map 1:1 what
#     goes in the envoy configuration.
# @param capitalize_headers
#     If true, will capitalize headers for HTTP/1.1 requests
# @param global_tlsparams
#     Set Tlsparams for the non-SNI listener:
#       cipher_suites => <= TLSv1.2 cipher suites
#       ecdh_curves   => ECDH curves
# @param stek_files
#     Set Session Ticket Encryption files to be used on both non-SNI and SNI listeners
# @param global_alpn_protocols
#     Set ALPN protocols on the non-SNI listener. This is required to enable
#     downstream H2 support
# @param idle_timeout
#     The time in seconds to wait before closing a keepalive connection when inactive.
# @param max_requests_per_conn
#     The maximum number of requests to send over a connection
# @param lua_script
#     lua script contents  to use as a global lua script. Only available for V3 configuration
define envoyproxy::tls_terminator(
    Variant[Array[Envoyproxy::Tlsconfig], Array[Envoyproxy::TlsconfigV3]] $upstreams                 = [],
    Boolean                                                               $access_log                = false,
    Boolean                                                               $websockets                = false,
    Boolean                                                               $use_remote_address        = true,
    Integer                                                               $fast_open_queue           = 0,
    Float                                                                 $connect_timeout           = 1.0,
    Float                                                                 $upstream_response_timeout = 65.0,
    Boolean                                                               $capitalize_headers        = false,
    Boolean                                                               $listen_ipv6               = false,
    Hash[String, String]                                                  $response_headers_to_add   = {},
    Optional[Hash]                                                        $retry_policy              = undef,
    Optional[Stdlib::Port]                                                $redir_port                = undef,
    Optional[Array[Envoyproxy::Tlscertificate]]                           $global_certs              = undef,
    Optional[Envoyproxy::Tlsparams]                                       $global_tlsparams          = undef,
    Optional[Array[Stdlib::UnixPath]]                                     $stek_files                = undef,
    Optional[Envoyproxy::Alpn]                                            $global_alpn_protocols     = undef,
    Optional[Float]                                                       $idle_timeout              = undef,
    Optional[Integer]                                                     $max_requests_per_conn     = undef,
    Optional[String]                                                      $lua_script                = undef,
) {

    # First of all, we can't configure a tls terminator if envoy is not installed.
    if !defined(Class['envoyproxy']) {
        fail('envoyproxy::tls_terminator should only be used once the envoyproxy class is declared.')
    }

    $listeners_template = $upstreams[0] ? {
        Envoyproxy::Tlsconfig   => 'envoyproxy/tls_terminator/listener.yaml.erb',
        Envoyproxy::TlsconfigV3 => 'envoyproxy/tls_terminator/listener.v3.yaml.erb',
    }

    # As this is a fundamental function, install it with high priority
    # Please note they will be removed if we remove the terminator declaration.

    # We need a separate definition for each upstream cluster
    $upstreams.each |$upstream| {
        $upstream_name = $upstream['upstream'] ? {
            Envoyproxy::Ipupstream  => "local_port_${upstream['upstream']['port']}",
            Envoyproxy::Udsupstream => "local_path_${upstream['upstream']['path']}",
        }

        if !defined(Envoyproxy::Cluster["cluster_${upstream_name}"]) { # nothing wrong with several listeners using the same cluster
            envoyproxy::cluster { "cluster_${upstream_name}":
                priority => 0,
                content  => template('envoyproxy/tls_terminator/cluster.yaml.erb'),
            }
        }
    }
    envoyproxy::listener { "tls_terminator_${name}":
        priority => 0,
        content  => template($listeners_template),
    }
    if $redir_port {
        # Redirection is less important, install it at the bottom of the pyle.
        envoyproxy::listener { "http_redirect_${name}":
            priority => 99,
            content  => template('envoyproxy/tls_terminator/redirect_listener.yaml.erb')
        }
    }
}
