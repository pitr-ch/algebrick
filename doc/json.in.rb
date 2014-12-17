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

require 'algebrick/serializer'
require 'multi_json'

# Prepare a message for sending.
serializer   = Algebrick::Serializer.new
request      = CreateUser[User['root', 'lajDh4']]
raw_request  = MultiJson.dump serializer.dump(request)

# Receive the message.
response     = match serializer.load(MultiJson.load(raw_request)),
                     (on CreateUser.(~any) do |user|
                       # create the user and send success
                       Success[user]
                     end)

# Send response.
response_raw = MultiJson.dump serializer.dump(response)

# Receive response.
serializer.load(MultiJson.load(response_raw))


