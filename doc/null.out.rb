extend Algebrick::Matching                         # => main

def deliver_email(email)
  true
end                                                # => nil

Contact = Algebrick.type do |contact|
  variants Null = atom, contact
  fields username: String, email: String
end
# => Contact(Null | Contact(username: String, email: String))

module Contact
  def username
    match self,
          Null >> 'no name',
          Contact >-> { self[:username] }
  end
  def email
    match self,
          Null >> 'no email',
          Contact >-> { self[:email] }
  end
  def deliver_personalized_email
    match self,
          Null >> true,
          Contact >-> { deliver_email(self.email) }
  end
end                                                # => nil

peter  = Contact['peter', 'example@dot.com']       # => Contact[username: peter, email: example@dot.com]
john   = Contact[username: 'peter', email: 'example@dot.com']
# => Contact[username: peter, email: example@dot.com]
nobody = Null                                      # => Null

[peter, john, nobody].map &:email
# => ["example@dot.com", "example@dot.com", "no email"]
[peter, john, nobody].map &:deliver_personalized_email
# => [true, true, true]
