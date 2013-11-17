extend Algebrick::Matching                         # => main

# Definition of data structures
Tree = Algebrick.type do |tree|
  variants Tip  = type,
           Node = type { fields value: Object, left: tree, right: tree }
end                                                # => Tree(Tip | Node)

module Tree
  def depth
    match self,
          Tip.to_m >> 0,
          Node.(_, ~any, ~any) >-> left, right do
            1 + [left.depth, right.depth].max
          end
  end
end                                                # => nil

tree = Node[2,
            Tip,
            Node[5,
                 Node[4, Tip, Tip],
                 Node[6, Tip, Tip]]]
# => Node[value: 2, left: Tip, right: Node[value: 5, left: Node[value: 4, left: Tip, right: Tip], right: Node[value: 6, left: Tip, right: Tip]]]
tree.depth                                         # => 3

# Domain model specification
Arch = Algebrick.type do
  variants I386 = atom, Amd64 = atom, Armel = atom
end                                                # => Arch(I386 | Amd64 | Armel)

Package = Algebrick.type do
  Deb = type do
    fields! id:       String, version: String,
            revision: Integer, arch: Arch
  end
  Rpm = type do
    fields! id:      String, version: String,
            release: Integer, arch: Arch
  end
  variants Deb, Rpm
end                                                # => Package(Deb | Rpm)

module Package
  def pkg_name
    match self,
          Deb >-> { '%s_%s-%s_%s.deb' % self },
          Rpm >-> { '%s-%s-%s-%s.rpm' % self }
  end
end                                                # => nil

module Arch
  def to_s
    name.downcase
    #match self,
    #      I386  => 'i386',
    #      Amd64 => 'amd64',
    #      Armel => 'armel'
  end
end                                                # => nil

dep = Deb['apt', '1.2.3', 4, I386]
# => Deb[id: apt, version: 1.2.3, revision: 4, arch: i386]
rom = Rpm['yum', '1.2.3', 4, Amd64]
# => Rpm[id: yum, version: 1.2.3, release: 4, arch: amd64]
dep.pkg_name                                       # => "apt_1.2.3-4_i386.deb"
rom.pkg_name                                       # => "yum-1.2.3-4-amd64.rpm"

# Avoiding nil errors with Maybe
Maybe = Algebrick.type do
  variants None = type,
           Some = type { fields Integer }
end                                                # => Maybe(None | Some)
# wrap values which can be nil into maybe and then match to avoid nil errors
def add(value)
  @sum ||= 0
  match value,
        None >> @sum,
        Some.(~any) >-> int { @sum += int }
end                                                # => nil
add None                                           # => 0
add Some[2]                                        # => 2
add Some[-1]                                       # => 1
add 2 rescue $!
# => #<RuntimeError: no match for (Fixnum) '2' by any of None.to_m, Some.(~any)>
