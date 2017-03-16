module Domains
    def self.get(app_root, app_domain)
        shell = Chef::ShellOut.new(:user => 'root')
        command = "php #{app_root}/get-mapped-domains.php"
        result = shell.shell_out(command)
        
        Chef::Log.info("**************** DOMAINS RESULT: #{result.stdout}")
        Chef::Log.info("**************** DOMAINS ERROR:  #{result.stderr}")
        domains = result.stdout.split("\n")
        domains.unshift("#{app_domain}")

        return domains
    end
end