extend Algebrick::Matching

def deliver_email(email)
  true
end

Contact = Algebrick.type do |c|
  Null = type
  variants Null, c
  fields username: String, email: String
end

module Contact
  def null?
    Null === self
  end

  def username
    match self,
          Null.to_m >> 'no name',
          Contact.() >-> { self[:username] }
  end

  def email
    match self,
          Null.to_m >> 'no email',
          Contact.() >-> { self[:email] }
  end

  def deliver_personalized_email
    match self,
          Null.to_m >> true,
          Contact.() >-> { deliver_email(self.email) }
  end
end

peter  = Contact['peter', 'example@dot.com']
john   = Contact[username: 'peter', email: 'example@dot.com']
nobody = Null

[peter, john, nobody].map &:email
[peter, john, nobody].map &:deliver_personalized_email
