extend Algebrick::Matching                         # => main

# lets define message-protocol for a cross-process communication
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

# prepare a message for sending
create_user_request     = CreateUser[User['root', 'lajDh4']]
# => CreateUser[User[login: root, password: lajDh4]]
raw_create_user_request = MultiJson.dump create_user_request.to_hash
# => "{\"algebrick\":\"CreateUser\",\"fields\":[{\"algebrick\":\"User\",\"login\":\"root\",\"password\":\"lajDh4\"}]}"

# receive the message
response                = match Message.from_hash(MultiJson.load(raw_create_user_request)),
                                CreateUser.(~any) >-> user { Success[user] }
# => Success[User[login: root, password: lajDh4]]

# send response
response_raw            = MultiJson.dump response.to_hash
# => "{\"algebrick\":\"Success\",\"fields\":[{\"algebrick\":\"User\",\"login\":\"root\",\"password\":\"lajDh4\"}]}"

# receive response
Message.from_hash(MultiJson.load(response_raw))    # => Success[User[login: root, password: lajDh4]]


