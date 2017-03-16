module Domains
    class ShellOut
        include Chef::Mixin::ShellOut
    end
    
    def self.get(app_root, app_domain)
        shell = Domains::ShellOut.new
        command = "php #{app_root}/get-mapped-domains.php"
        result = shell.shell_out(command)
        
        Chef::Log.info("**************** DOMAINS RESULT: #{result.stdout}")
        Chef::Log.info("**************** DOMAINS ERROR:  #{result.stderr}")
        domains = result.stdout.split("\n")
        domains.unshift("#{app_domain}")

        return domains
    end
end