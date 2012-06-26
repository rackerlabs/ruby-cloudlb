module CloudLB
  class Exception

    class CloudLBError < StandardError

      attr_reader :response_body
      attr_reader :response_code

      def initialize(message, code, response_body)
        @response_code=code
        @response_body=response_body
        super(message)
      end

    end
    
    class ServiceFault                < CloudLBError # :nodoc:
    end
    class LoadBalancerFault           < CloudLBError # :nodoc:
    end
    class ServiceUnavailable          < CloudLBError # :nodoc:
    end
    class Unauthorized                < CloudLBError # :nodoc:
    end
    class BadRequest                  < CloudLBError # :nodoc:
    end
    class ItemNotFound                < CloudLBError # :nodoc:
    end
    class OverLimit                   < CloudLBError # :nodoc:
    end
    class OutOfVirtualIps             < CloudLBError # :nodoc:
    end
    class ImmutableEntity             < CloudLBError # :nodoc:
    end
    class UnprocessableEntity         < CloudLBError # :nodoc:
    end
    class Other                       < CloudLBError # :nodoc:
    end
    
    # Plus some others that we define here
    
    class ExpiredAuthToken            < StandardError # :nodoc:
    end
    class MissingArgument             < StandardError # :nodoc:
    end
    class InvalidArgument             < StandardError # :nodoc:
    end
    class Authentication              < StandardError # :nodoc:
    end
    class Connection                  < StandardError # :nodoc:
    end
    class Syntax                      < StandardError # :nodoc:
    end
    
        
    # In the event of a non-200 HTTP status code, this method takes the HTTP response, parses
    # the JSON from the body to get more information about the exception, then raises the
    # proper error.  Note that all exceptions are scoped in the CloudLB::Exception namespace.
    def self.raise_exception(response)
      return if response.code =~ /^20.$/
      begin
        fault = nil
        info = nil
        JSON.parse(response.body).each_pair do |key, val|
			    fault=key
			    info=val
			  end
        exception_class = self.const_get(fault[0,1].capitalize+fault[1,fault.length])
        raise exception_class.new(info["message"], response.code, response.body)
      rescue NameError, JSON::ParserError
        raise CloudLB::Exception::Other.new("The server returned status #{response.code} with body #{response.body}", response.code, response.body)
      end
    end
    
  end
end

