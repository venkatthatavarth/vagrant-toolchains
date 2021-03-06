include apt
require 'facter'
class docker {


  # create docker group
  group { 'docker':
    ensure => 'present'
  }
  group { 'vagrant':
    ensure => 'present'
  }

  # declare vagrant user as a virtual resource
  # http://serverfault.com/a/416284/135880
  # https://docs.puppet.com/puppet/latest/reference/lang_virtual.html#declaring-a-virtual-resource
  @user { 'vagrant':
    groups     => ['vagrant','docker'],
  }

  # realize virtual resource above.
  realize(User['vagrant'])

  # docker key
  # apt::key {'58118E89F3A912897C070ADBF76221572C52609D':
  #   options => '--keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D',
  # } ->  # docker source

  apt::key {'58118E89F3A912897C070ADBF76221572C52609D':
    id => '58118E89F3A912897C070ADBF76221572C52609D',
    server => 'hkp://ha.pool.sks-keyservers.net:80',
  }

  apt::source { 'docker':
  location => 'http://apt.dockerproject.org/repo',
  repos    => 'main',
  release  => 'ubuntu-xenial',
  before => Exec['apt_update'],
  } ~>  # packages needed for docker
  package { 'apt-transport-https':
    ensure => 'latest',
    require => Exec['apt_update']
  } ~>
  package { 'ca-certificates':
    ensure => 'latest'
  } ~>  # install docker
  package {"docker-engine":
    ensure => 'latest'
  } ~>
  # deploy templated docker conf.
  file {'/etc/systemd/system/docker.service':
    ensure => file,
    content => template('docker/systemd.docker'),
    notify => Exec['systemctl-daemon-reload'],
    mode => '0644',
    owner => 'root',
    group => 'root'
  }
  exec {'systemctl-daemon-reload':
    command => '/usr/bin/sudo /bin/systemctl daemon-reload',
    notify => Service['docker']
  }
  # ensure docker service running.
  service {'docker':
    ensure => 'running'
  }
  # download docker compose
  common::remote_file{'/usr/local/bin/docker-compose':
    remote_location => 'https://github.com/docker/compose/releases/download/1.17.1/docker-compose-Linux-x86_64',
    mode            => '0777',
  }

}
