extend Algebrick::DSL
extend Algebrick::Matching

# lets define message-protocol for a cross-process communication
type_def do
  message === request | response

  request === create_user(user) | get_user(login: String) | delete_user(user)
  user(login: String, password: String)

  response === success(Object) | failure(error: String)
end; nil

require 'multi_json'

# prepare a message for sending
create_user_request     = CreateUser[User['root', 'lajDh4']]
raw_create_user_request = MultiJson.dump create_user_request.to_hash

# receive the message
response                = match Message.from_hash(MultiJson.load(raw_create_user_request)),
                                CreateUser.(~any) --> user { Success[user] }

# send response
response_raw            = MultiJson.dump response.to_hash

# receive response
Message.from_hash(MultiJson.load(response_raw))


