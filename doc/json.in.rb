extend Algebrick::Matching

# lets define message-protocol for a cross-process communication
Request = Algebrick.type do
  User       = type { fields login: String, password: String }
  CreateUser = type { fields User }
  GetUser    = type { fields login: String }

  variants CreateUser, GetUser
end

Response = Algebrick.type do
  Success = type { fields Object }
  Failure = type { fields error: String }

  variants Success, Failure
end

Message = Algebrick.type { variants Request, Response }

require 'multi_json'

# prepare a message for sending
create_user_request     = CreateUser[User['root', 'lajDh4']]
raw_create_user_request = MultiJson.dump create_user_request.to_hash

# receive the message
response                = match Message.from_hash(MultiJson.load(raw_create_user_request)),
                                CreateUser.(~any) >-> user { Success[user] }

# send response
response_raw            = MultiJson.dump response.to_hash

# receive response
Message.from_hash(MultiJson.load(response_raw))


