extend Algebrick::DSL                              # => main
extend Algebrick::Matching                         # => main

# lets define message-protocol for a cross-process communication
type_def do
  message === request | response

  request === create_user(user) | get_user(login: String) | delete_user(user)
  user(login: String, password: String)

  response === success(Object) | failure(error: String)
end; nil                                           # => nil

require 'multi_json'                               # => true

# prepare a message for sending
create_user_request     = CreateUser[User['root', 'lajDh4']]
# => CreateUser[User[login: root, password: lajDh4]]
raw_create_user_request = MultiJson.dump create_user_request.to_hash
# => "{\"CreateUser\":[{\"User\":{\"login\":\"root\",\"password\":\"lajDh4\"}}]}"

# receive the message
response                = match Message.from_hash(MultiJson.load(raw_create_user_request)),
                                CreateUser.(~any) --> user { Success[user] }
# => Success[User[login: root, password: lajDh4]]

# send response
response_raw            = MultiJson.dump response.to_hash
# => "{\"Success\":[{\"User\":{\"login\":\"root\",\"password\":\"lajDh4\"}}]}"

# receive response
Message.from_hash(MultiJson.load(response_raw))    # => Success[User[login: root, password: lajDh4]]


