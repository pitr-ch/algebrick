extend Algebrick::Matching                         # => main

# Lets define message-protocol for a cross-process communication.
Request = Algebrick.type do
  User = type { fields login: String, password: String }

  variants CreateUser = type { fields User },
           GetUser    = type { fields login: String }
end                                                # => Request(CreateUser | GetUser)

Response = Algebrick.type do
  variants Success = type { fields Object },
           Failure = type { fields error: String }
end                                                # => Response(Success | Failure)

Message = Algebrick.type { variants Request, Response }
# => Message(Request | Response)

require 'multi_json'                               # => true

# Prepare a message for sending.
request      = CreateUser[User['root', 'lajDh4']]
# => CreateUser[User[login: root, password: lajDh4]]
raw_request  = MultiJson.dump request.to_hash
# => "{\"algebrick\":\"CreateUser\",\"fields\":[{\"algebrick\":\"User\",\"login\":\"root\",\"password\":\"lajDh4\"}]}"

# Receive the message.
response     = match Message.from_hash(MultiJson.load(raw_request)),
                     CreateUser.(~any) >-> user do
                       # create the user and send success
                       Success[user]
                     end                           # => Success[User[login: root, password: lajDh4]]

# Send response.
response_raw = MultiJson.dump response.to_hash
# => "{\"algebrick\":\"Success\",\"fields\":[{\"algebrick\":\"User\",\"login\":\"root\",\"password\":\"lajDh4\"}]}"

# Receive response.
Message.from_hash(MultiJson.load(response_raw))    # => Success[User[login: root, password: lajDh4]]


