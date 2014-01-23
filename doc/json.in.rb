extend Algebrick::Matching

# Lets define message-protocol for a cross-process communication.
Request = Algebrick.type do
  User = type { fields login: String, password: String }

  variants CreateUser = type { fields User },
           GetUser    = type { fields login: String }
end

Response = Algebrick.type do
  variants Success = type { fields Object },
           Failure = type { fields error: String }
end

Message = Algebrick.type { variants Request, Response }

require 'algebrick/serializers/to_json'

# Prepare a message for sending.
serializer   = Algebrick::Serializers::Chain.build(Algebrick::Serializers::StrictToHash.new,
                                                   Algebrick::Serializers::ToJson.new); nil
request      = CreateUser[User['root', 'lajDh4']]
raw_request  = serializer.generate request

# Receive the message.
response     = match serializer.parse(raw_request),
                     CreateUser.(~any) >-> user do
                       # create the user and send success
                       Success[user]
                     end

# Send response.
response_raw = serializer.generate response

# Receive response.
serializer.parse response_raw


