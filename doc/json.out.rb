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

require 'algebrick/serializers/to_json'            # => true

# Prepare a message for sending.
serializer   = Algebrick::Serializers::Chain.build(Algebrick::Serializers::StrictToHash.new,
                                                   Algebrick::Serializers::ToJson.new); nil
# => nil
request      = CreateUser[User['root', 'lajDh4']]
# => CreateUser[User[login: root, password: lajDh4]]
raw_request  = serializer.generate request
# => "{\"algebrick_type\":\"CreateUser\",\"algebrick_fields\":[{\"algebrick_type\":\"User\",\"login\":\"root\",\"password\":\"lajDh4\"}]}"

# Receive the message.
response     = match serializer.parse(raw_request),
                     CreateUser.(~any) >-> user do
                       # create the user and send success
                       Success[user]
                     end                           # => Success[User[login: root, password: lajDh4]]

# Send response.
response_raw = serializer.generate response
# => "{\"algebrick_type\":\"Success\",\"algebrick_fields\":[{\"algebrick_type\":\"User\",\"login\":\"root\",\"password\":\"lajDh4\"}]}"

# Receive response.
serializer.parse response_raw                      # => Success[User[login: root, password: lajDh4]]


