# == Class: python
#
# Installs and manages python, python-dev, python-virtualenv and Gunicorn.
#
# === Parameters
#
# [*version*]
#  Python version to install. Beware that valid values for this differ a) by
#  the provider you choose and b) by the osfamily/operatingsystem you are using.
#  Default: system default
#  Allowed values:
#   - provider == pip: everything pip allows as a version after the 'python=='
#   - else: 'system', 'pypy', 3/3.3/...
#      - Be aware that 'system' usually means python 2.X.
#      - 'pypy' actually lets us use pypy as python.
#      - 3/3.3/... means you are going to install the python3/python3.3/...
#        package, if available on your osfamily.
#
# [*pip*]
#  Install python-pip. Default: true
#
# [*dev*]
#  Install python-dev. Default: false
#
# [*virtualenv*]
#  Install python-virtualenv. Default: false, also accepts 'pip' which will
#  install latest virtualenv from pip rather than package manager
#
# [*gunicorn*]
#  Install Gunicorn. Default: false
#
# [*manage_gunicorn*]
#  Allow Installation / Removal of Gunicorn. Default: true
#
# [*provider*]
#  What provider to use for installation of the packages, except gunicorn.
#  Default: system default provider
#  Allowed values: 'pip'
#
# [*use_epel*]
#  Boolean to determine if the epel class is used. Default: true
#
# === Examples
#
# class { 'python':
#   version    => 'system',
#   pip        => true,
#   dev        => true,
#   virtualenv => true,
#   gunicorn   => true,
# }
#
# === Authors
#
# Sergey Stankevich
# Garrett Honeycutt <code@garretthoneycutt.com>
#
class python (
  $version                   = $python::params::version,
  $pip                       = $python::params::pip,
  $dev                       = $python::params::dev,
  $virtualenv                = $python::params::virtualenv,
  $gunicorn                  = $python::params::gunicorn,
  $manage_gunicorn           = $python::params::manage_gunicorn,
  $provider                  = $python::params::provider,
  $valid_versions            = $python::params::valid_versions,
  $python_pips               = { },
  $python_virtualenvs        = { },
  $python_pyvenvs            = { },
  $python_requirements       = { },
  $use_epel                  = $python::params::use_epel,
) inherits python::params{

  # validate inputs
  if $provider != undef {
    validate_re($provider, ['^(pip|scl|rhscl)$'], 'Only "pip", "rhscl", and "scl" are valid providers besides the system default.')
  }

  if $provider == 'pip' {
    validate_re($version, ['^(2\.[4-7]\.\d|3\.\d\.\d)$','^system$'])
  } elsif ($provider == 'scl' or $provider == 'rhscl') {
    validate_re($version, concat(['python33', 'python27', 'rh-python34'], $valid_versions))
  } else {
    validate_re($version, concat(['system', 'pypy'], $valid_versions))
  }

  $exec_prefix = $provider ? {
    'scl'   => "scl enable ${version} -- ",
    'rhscl' => "scl enable ${version} -- ",
    default => '',
  }

  validate_bool($pip)
  validate_bool($dev)
  validate_bool($virtualenv)
  validate_bool($gunicorn)
  validate_bool($manage_gunicorn)
  validate_bool($use_epel)

  # Module compatibility check
  $compatible = [ 'Debian', 'RedHat', 'Suse' ]
  if ! ($::osfamily in $compatible) {
    fail("Module is not compatible with ${::operatingsystem}")
  }

  # Anchor pattern to contain dependencies
  anchor { 'python::begin': } ->
  class { 'python::install': } ->
  class { 'python::config': } ->
  Exec<| tag == 'python-virtualenv' |> ->
  anchor { 'python::end': }

  # Allow hiera configuration of python resources
  create_resources('python::pip', $python_pips)
  create_resources('python::pyvenv', $python_pyvenvs)
  create_resources('python::virtualenv', $python_virtualenvs)
  create_resources('python::requirements', $python_requirements)

}
