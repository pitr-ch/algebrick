extend Algebrick::Matching

def deliver_email(email)
  true
end

Contact = Algebrick.type do |contact|
  variants Null = atom, contact
  fields username: String, email: String
end

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
end

peter  = Contact['peter', 'example@dot.com']
john   = Contact[username: 'peter', email: 'example@dot.com']
nobody = Null

[peter, john, nobody].map &:email
[peter, john, nobody].map &:deliver_personalized_email
