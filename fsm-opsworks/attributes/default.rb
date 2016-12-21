# Default configuration options our cookbook

# Force logins via https (http://codex.wordpress.org/Administration_Over_SSL#To_Force_SSL_Logins_and_SSL_Admin_Access)
default['wordpress']['force_secure_logins'] = false
default['wordpress']['multisite']['default_site'] = 1
default['wordpress']['sunrise'] = false
default['wordpress']['debug'] = false
default['wordpress']['site_url'] = false
default['wordpress']['fsm_google_public_api_key'] = false
default['wordpress']['wpmudev_limit_to_user'] = false
default['wordpress']['aws_access_key_id'] = false
default['wordpress']['aws_access_key_secret'] = false
default['wordpress']['fsm_smtp']['fsm_smtp_host'] = false
default['wordpress']['fsm_smtp']['fsm_smtp_port'] = false
default['wordpress']['fsm_smtp']['fsm_smtp_user'] = false
default['wordpress']['fsm_smtp']['fsm_smtp_pass'] = false
default['wordpress']['fsm_smtp']['fsm_smtp_auth'] = false
default['wordpress']['fsm_smtp']['fsm_smtp_secu'] = false
default['wordpress']['fsm_circular_api_secret'] = false
default['wordpress']['fsm_circular_response_signing_key'] = false
default['wordpress']['fsm_circular_processor_endpoint'] = false
default['wordpress']['fsm_circular_api_key'] = false
default['wordpress']['multisite']['enabled'] = false
default['wordpress']['multisite']['subdomain_install'] = false
default['wordpress']['multisite']['domain_current_site'] = false
default['wordpress']['multisite']['default_site'] = 1
default['wordpress']['salt'] = false
default['wordpress']['batcache'] = false
default['wordpress']['wordfence'] = false
default['wordpress']['max_upload_size'] = '32M'
default['wordpress']['max_execution_time'] = '180'
default['wordpress']['exclude_plugins'] = []
default['wordpress']['exclude_themes'] = []
default['wordpress']['memcached_servers'] = false
default['wordpress']['wp_cache_key_salt'] = false

default['letsencrypt']['get_certificates'] = false
default['letsencrypt']['admin_email'] = ''

default[:cwlogs][:logfile] = '/var/log/aws/opsworks/opsworks-agent.statistics.log'
default[:cwlogs][:region] = 'us-west-2'