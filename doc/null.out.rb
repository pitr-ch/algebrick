extend Algebrick::DSL                              # => main
extend Algebrick::Matching                         # => main

def deliver_email(email)
  true
end                                                # => nil

type_def { contact === null | contact(username: String, email: String) }
# => [Contact(Null | Contact(username: String, email: String)), Null]

module Contact
  def null?
    Null === self
  end

  def username
    match self,
          Null.to_m >> 'no name',
          Contact.() --> { self[:username] }
  end

  def email
    match self,
          Null.to_m >> 'no email',
          Contact.() --> { self[:email] }
  end

  def deliver_personalized_email
    match self,
          Null.to_m >> true,
          Contact.() --> { deliver_email(self.email) }
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

