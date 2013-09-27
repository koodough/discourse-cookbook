# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.hostname = "discourse-vagrant"
  config.vm.box = "precise64"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"

  # config.vm.network :private_network, ip: "33.33.33.10"
  config.vm.network :forwarded_port, {guest: 8000, host: 8000}
  config.vm.network :forwarded_port, {guest: 80, host: 8888}

  # config.vm.synced_folder "../data", "/vagrant_data"

  config.ssh.timeout       = 120
  config.ssh.max_tries     = 40
  config.ssh.forward_agent = true

  config.berkshelf.enabled = true

  config.vm.provision :chef_solo do |chef|
    chef.log_level = :debug
    chef.json = {
      :nginx => {
        :repo_source => "nginx",
        :default_site_enabled => false,
      },
      :postfix => {   # Mailgun
        :smtpd_use_tls => "no",
        #:smtpd_tls_security_level => "may",
        :relayhost => "smtp.mailgun.org",
        :smtp_sasl_auth_enable => "yes",
        :smtp_sasl_password_maps => "static:postmaster@rocoto.mailgun.org:MyAwesomeKey",   # Change this
        :smtp_sasl_security_options => "noanonymous",
      },
      :discourse => {
        :release => "v0.9.6",
        :secret_token => "Kittens rule the world!!!",   # Obvioulsy you need to change this
      },
      :postgresql => {
        :password => {
          # https://github.com/opscode-cookbooks/postgresql#chef-solo-note
          :postgres => "123456",  # => '123456'
        },
      },
      :supervisor => {
        :version => "3.0",
      },
    }

    chef.run_list = [
      "recipe[discourse::default]",
    ]
  end
end
