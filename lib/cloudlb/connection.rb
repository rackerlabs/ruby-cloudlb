module CloudLB
  class Connection
    
    attr_reader   :authuser
    attr_reader   :authkey
    attr_accessor :authtoken
    attr_accessor :authok
    attr_accessor :lbmgmthost
    attr_accessor :lbmgmtpath
    attr_accessor :lbmgmtport
    attr_accessor :lbmgmtscheme
    attr_reader   :auth_url
    attr_reader   :region
    
    # Creates a new CloudLB::Connection object.  Uses CloudLB::Authentication to perform the login for the connection.
    #
    # Setting the retry_auth option to false will cause an exception to be thrown if your authorization token expires.
    # Otherwise, it will attempt to reauthenticate.
    #
    # This will likely be the base class for most operations.
    #
    # The constructor takes a hash of options, including:
    #
    #   :username - Your Rackspace Cloud username *required*
    #   :api_key - Your Rackspace Cloud API key *required*
    #   :region - The region in which to manage load balancers. Current options are :dfw (Rackspace Dallas/Ft. Worth Datacenter)
    #             and :ord (Rackspace Chicago Datacenter). *required*
    #   :auth_url - The URL to use for authentication.  (defaults to Rackspace USA).
    #   :retry_auth - Whether to retry if your auth token expires (defaults to true)
    #
    #   lb = CloudLB::Connection.new(:username => 'YOUR_USERNAME', :api_key => 'YOUR_API_KEY', :region => :dfw)
    def initialize(options = {:retry_auth => true}) 
      @authuser = options[:username] || (raise CloudLB::Exception::Authentication, "Must supply a :username")
      @authkey = options[:api_key] || (raise CloudLB::Exception::Authentication, "Must supply an :api_key")
      @region = options[:region] || (raise CloudLB::Exception::Authentication, "Must supply a :region")
      @retry_auth = options[:retry_auth]
      @auth_url = options[:auth_url] || CloudLB::AUTH_USA
      @snet = ENV['RACKSPACE_SERVICENET'] || options[:snet]
      @authok = false
      @http = {}
      CloudLB::Authentication.new(self)
    end
    
    # Returns true if the authentication was successful and returns false otherwise.
    #
    #   lb.authok?
    #   => true
    def authok?
      @authok
    end
    
    # Returns the list of available load balancers.  By default, it hides deleted load balancers (which hang around unusable
    # for 90 days). To show all load balancers, including deleted ones, pass in :show_deleted => true.
    #
    # Information returned includes:
    #   * :id - The numeric ID of this load balancer
    #   * :name - The name of the load balancer
    #   * :status - The current state of the load balancer (ACTIVE, BUILD, PENDING_UPDATE, PENDING_DELETE, SUSPENDED, ERROR)
    #   * :port - The TCP port that the load balancer listens on
    #   * :protocol - The network protocol being balanced.
    #   * :algorithm - The balancing algorithm used by this load balancer
    #   * :created[:time] - The time that the load balancer was created
    #   * :updated[:time] - The most recent time that the load balancer was modified
    #   * :virutalIps - Information about the Virtual IPs providing service to this load balancer.
    def list_load_balancers(options={})
      response = lbreq("GET",lbmgmthost,"#{lbmgmtpath}/loadbalancers",lbmgmtport,lbmgmtscheme)
      CloudLB::Exception.raise_exception(response) unless response.code.to_s.match(/^20.$/)
      balancers = CloudLB.symbolize_keys(JSON.parse(response.body)["loadBalancers"])
      return options[:show_deleted] == true ? balancers : balancers.select{|lb| lb[:status] != "DELETED"}
    end
    alias :load_balancers :list_load_balancers
    
    # Returns a CloudLB::Balancer object for the given load balancer ID number.
    #
    #    >> lb.get_load_balancer(2)
    def get_load_balancer(id)
      CloudLB::Balancer.new(self,id)
    end
    alias :load_balancer :get_load_balancer
    
    # Creates a brand new load balancer under your account.
    #
    # A minimal request must pass in :name, :protocol, :port, :nodes, and either :virtual_ip_ids or :virtual_ip_types.
    #
    # Options:
    # :name - the name of the load balancer.  Limted to 128 characters or less.
    # :protocol - the protocol to balance. Must be a valid protocol. Get the list of available protocols with the list_protocols
    #             command. Supported in the latest docs are: HTTP, HTTPS, FTP, IMAPv4, IMAPS, POP3, POP3S, LDAP, LDAPS, SMTP
    # :nodes - An array of hashes for each node to be balanced.  The hash should contain the address of the target server, 
    #          the port on the target server, and the condition ("ENABLED", "DISABLED", "DRAINING"). Optionally supply a :weight for use
    #          in the WEIGHTED_ algorithms.
    #          {:address => "1.2.3.4", :port => "80", :condition => "ENABLED", :weight => 1}
    # :port - the port that the load balancer listens on. *required*
    # :algorithm - A valid balancing algorithm.  Use the algorithms method to get the list. Valid in the current documentation
    #              are RANDOM (default), LEAST_CONNECTIONS, ROUND_ROBIN, WEIGHTED_LEAST_CONNECTIONS, WEIGHTED_ROUND_ROBIN
    # :virtual_ip_id -  If you have existing virtual IPs and would like to reuse them in a different balancer (for example, to
    #                   load balance both HTTP and HTTPS on the same IP), you can pass in an array of the ID numbers for those
    #                   virtual IPs
    # :virtual_ip_type - Alternately, you can get new IP addresses by passing in the type of addresses that you
    #                     want to obtain.  Values are "PUBLIC" or "PRIVATE".
    def create_load_balancer(options = {})
      body = Hash.new
      body[:name] = options[:name] or raise CloudLB::Exception::MissingArgument, "Must provide a name to create a load balancer"
      (raise CloudLB::Exception::Syntax, "Load balancer name must be 128 characters or less") if options[:name].size > 128
      (raise CloudLB::Exception::Syntax, "Must provide at least one node in the :nodes array") if (!options[:nodes].is_a?(Array) || options[:nodes].size < 1)
      body[:protocol] = options[:protocol] or raise CloudLB::Exception::MissingArgument, "Must provide a protocol to create a load balancer"
      body[:protocol].upcase! if body[:protocol]
      body[:port] = options[:port] if options[:port]
      body[:nodes] = options[:nodes]
      body[:algorithm] = options[:algorithm].upcase if options[:algorithm]
      if options[:virtual_ip_id]
        body['virtualIps'] = [{:id => options[:virtual_ip_id]}]
      elsif options[:virtual_ip_type]
        body['virtualIps'] = [{:type => options[:virtual_ip_type]}]
      end
      response = lbreq("POST",lbmgmthost,"#{lbmgmtpath}/loadbalancers",lbmgmtport,lbmgmtscheme,{},body.to_json)
      CloudLB::Exception.raise_exception(response) unless response.code.to_s.match(/^20.$/)
      body = JSON.parse(response.body)['loadBalancer']
      return get_load_balancer(body["id"])
    end
    
    # Returns a list of protocols that are currently supported by the Cloud Load Balancer product.
    #
    #   >> lb.list_protocols
    #   => [{:port=>21, :name=>"FTP"}, {:port=>80, :name=>"HTTP"}, {:port=>443, :name=>"HTTPS"}, {:port=>993, :name=>"IMAPS"}, {:port=>143, :name=>"IMAPv4"}, {:port=>389, :name=>"LDAP"}, {:port=>636, :name=>"LDAPS"}, {:port=>110, :name=>"POP3"}, {:port=>995, :name=>"POP3S"}, {:port=>25, :name=>"SMTP"}]
    def list_protocols
      response = lbreq("GET",lbmgmthost,"#{lbmgmtpath}/loadbalancers/protocols",lbmgmtport,lbmgmtscheme,{})
      CloudLB::Exception.raise_exception(response) unless response.code.to_s.match(/^20.$/)
      CloudLB.symbolize_keys(JSON.parse(response.body)["protocols"])    
    end
    alias :protocols :list_protocols
    
    # Returns a list of balancer algorithms that are currently supported by the Cloud Load Balancer product.
    #
    #   >> lb.list_algorithms
    #   => [{:name=>"LEAST_CONNECTIONS"}, {:name=>"RANDOM"}, {:name=>"ROUND_ROBIN"}, {:name=>"WEIGHTED_LEAST_CONNECTIONS"}, {:name=>"WEIGHTED_ROUND_ROBIN"}]
    def list_algorithms
      response = lbreq("GET",lbmgmthost,"#{lbmgmtpath}/loadbalancers/algorithms",lbmgmtport,lbmgmtscheme,{})
      CloudLB::Exception.raise_exception(response) unless response.code.to_s.match(/^20.$/)
      CloudLB.symbolize_keys(JSON.parse(response.body)["algorithms"])    
    end      
    alias :algorithms :list_algorithms
    
    
    # This method actually makes the HTTP REST calls out to the server. Relies on the thread-safe typhoeus
    # gem to do the heavy lifting.  Never called directly.
    def lbreq(method,server,path,port,scheme,headers = {},data = nil,attempts = 0) # :nodoc:
      if data
        unless data.is_a?(IO)
          headers['Content-Length'] = data.respond_to?(:lstat) ? data.stat.size : data.size
        end
      else
        headers['Content-Length'] = 0
      end
      hdrhash = headerprep(headers)
      url = "#{scheme}://#{server}#{path}"
      print "DEBUG: Data is #{data}\n" if (data && ENV['LOADBALANCERS_VERBOSE'])
      request = Typhoeus::Request.new(url,
                                      :body          => data,
                                      :method        => method.downcase.to_sym,
                                      :headers       => hdrhash,
                                      :verbose       => ENV['LOADBALANCERS_VERBOSE'] ? true : false)
      CloudLB.hydra.queue(request)
      CloudLB.hydra.run
      
      response = request.response
      print "DEBUG: Body is #{response.body}\n" if ENV['LOADBALANCERS_VERBOSE']
      raise CloudLB::Exception::ExpiredAuthToken if response.code.to_s == "401"
      response
    rescue Errno::EPIPE, Errno::EINVAL, EOFError
      # Server closed the connection, retry
      raise CloudLB::Exception::Connection, "Unable to reconnect to #{server} after #{attempts} attempts" if attempts >= 5
      attempts += 1
      @http[server].finish if @http[server].started?
      start_http(server,path,port,scheme,headers)
      retry
    rescue CloudLB::Exception::ExpiredAuthToken
      raise CloudLB::Exception::Connection, "Authentication token expired and you have requested not to retry" if @retry_auth == false
      CloudLB::Authentication.new(self)
      retry
    end
    
    
    private
    
    # Sets up standard HTTP headers
    def headerprep(headers = {}) # :nodoc:
      default_headers = {}
      default_headers["X-Auth-Token"] = @authtoken if (authok? && @account.nil?)
      default_headers["X-Storage-Token"] = @authtoken if (authok? && !@account.nil?)
      default_headers["Connection"] = "Keep-Alive"
      default_headers["Accept"] = "application/json"
      default_headers["Content-Type"] = "application/json"
      default_headers["User-Agent"] = "Cloud Load Balancers Ruby API #{VERSION}"
      default_headers.merge(headers)
    end    
        
  end
end
