# == Cloud Load Balancers API - SSL Termination
# By Robert Lee-Cann <robert.lee-cann@stylefoundry.co.uk>
module CloudLB
  class SSLTermination

    attr_reader :id
    attr_reader :securePort
    attr_reader :privatekey
    attr_reader :certificate
    attr_reader :intermediatecertificate
    attr_reader :enabled
    attr_reader :secureTrafficOnly

    # Creates a new CloudLB::SSLTermination object representing a SSL Termination instance.
    def initialize(load_balancer)
      @connection    = load_balancer.connection
      @load_balancer = load_balancer
      @lbmgmthost    = @connection.lbmgmthost
      @lbmgmtpath    = @connection.lbmgmtpath
      @lbmgmtport    = @connection.lbmgmtport
      @lbmgmtscheme  = @connection.lbmgmtscheme
      populate
      return self
    end

    # Updates the information about the current SSL Termination object by making an API call.
    def populate
      response = @connection.lbreq("GET",@lbmgmthost,"#{@lbmgmtpath}/loadbalancers/#{CloudLB.escape(@load_balancer.id.to_s)}/ssltermination",@lbmgmtport,@lbmgmtscheme)
      CloudLB::Exception.raise_exception(response) unless response.code.to_s.match(/^20.$/)
      data = JSON.parse(response.body)['sslTermination']
      @certificate              = data["certificate"]
      @enabled                  = data["enabled"]
      @secureTrafficOnly        = data["secureTrafficOnly"]
      @privatekey               = data["privatekey"]
      @intermediate_certificate = data["intermediatecertificate"]
      @securePort               = data["securePort"]
      true
    end
    alias :refresh :populate

    # Returns true if the ssl termination for this load balancer is defined and has data, returns false if not.
    def enabled?
      @enabled
    end

    # Deletes the SSL termination from the current load balancer object.  Returns true if successful, raises an exception otherwise.
    def destroy!
      response = @connection.lbreq("DELETE", @lbmgmthost, "#{@lbmgmtpath}/loadbalancers/#{CloudLB.escape(@load_balancer.id.to_s)}/ssltermination",@lbmgmtport,@lbmgmtscheme)
      CloudLB::Exception.raise_exception(response) unless response.code.to_s.match(/^202$/)
      true
    end

    # Sets a new value for secureTrafficOnly
    def secureTrafficOnly=(new_secureTrafficOnly=false)
      (raise CloudLB::Exception::MissingArgument, "Must provide a new value for secureTrafficOnly") unless new_secureTrafficOnly.is_a?(TrueClass) || new_secureTrafficOnly.is_a?(FalseClass)
      body = {"secureTrafficOnly" => new_secureTrafficOnly.to_s }
      update(body)
    end

    # Sets a new value for securePort
    def securePort=(new_securePort="443")
      (raise CloudLB::Exception::MissingArgument, "Must provide a new value for securePort") if new_securePort.to_s.empty?
      body = {"securePort" => new_securePort.to_s }
      update(body)
    end

    private

    def update(body)
      response = @connection.lbreq("PUT", @lbmgmthost, "#{@lbmgmtpath}/loadbalancers/#{CloudLB.escape(@load_balancer.id.to_s)}/ssltermination",@lbmgmtport,@lbmgmtscheme,{},body.to_json)
      CloudLB::Exception.raise_exception(response) unless response.code.to_s.match(/^20.$/)
      populate
      true
    end

  end
end
