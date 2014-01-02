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

require 'multi_json'

# Prepare a message for sending.
request      = CreateUser[User['root', 'lajDh4']]
raw_request  = MultiJson.dump request.to_hash

# Receive the message.
response     = match Message.from_hash(MultiJson.load(raw_request)),
                     CreateUser.(~any) >-> user do
                       # create the user and send success
                       Success[user]
                     end

# Send response.
response_raw = MultiJson.dump response.to_hash

# Receive response.
Message.from_hash(MultiJson.load(response_raw))


