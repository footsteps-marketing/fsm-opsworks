module Domains
    def self.get(app_root, app_domain)
        command = "php #{app_root}/get-mapped-domains.php"
        shell = Mixlib::ShellOut.new(command, :user => 'root')
        result = shell.run_command
        
        Chef::Log.info("**************** DOMAINS RESULT: #{shell.stdout}")
        Chef::Log.info("**************** DOMAINS ERROR:  #{shell.stderr}")
        domains = shell.stdout.split("\n")
        domains.unshift("#{app_domain}")

        return domains
    end
end