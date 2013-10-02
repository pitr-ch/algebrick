extend Algebrick::Matching

# Definition of data structures
Tree = Algebrick.type do |tree|
  Tip  = type
  Node = type { fields value: Object, left: tree, right: tree }

  variants Tip, Node
end

module Tree
  def depth
    match self,
          Tip.to_m >> 0,
          Node.(_, ~any, ~any) >-> left, right do
            1 + [left.depth, right.depth].max
          end
  end
end

tree = Node[2,
            Tip,
            Node[5,
                 Node[4, Tip, Tip],
                 Node[6, Tip, Tip]]]
tree.depth

# Domain model specification
Arch = Algebrick.type do
  variants I386 = atom, Amd64 = atom, Armel = atom
end

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
end

module Package
  def pkg_name
    match self,
          Deb >-> { '%s_%s-%s_%s.deb' % self },
          Rpm >-> { '%s-%s-%s-%s.rpm' % self }
  end
end

module Arch
  def to_s
    name.downcase
    #match self,
    #      I386  => 'i386',
    #      Amd64 => 'amd64',
    #      Armel => 'armel'
  end
end

dep = Deb['apt', '1.2.3', 4, I386]
rom = Rpm['yum', '1.2.3', 4, Amd64]
dep.pkg_name
rom.pkg_name

# Avoiding nil errors with Maybe
Maybe = Algebrick.type do
  None = type
  Some = type { fields Integer }
  variants None, Some
end
# wrap values which can be nil into maybe and then match to avoid nil errors
def add(value)
  @sum ||= 0
  match value,
        None >> @sum,
        Some.(~any) >-> int { @sum += int }
end
add None
add Some[2]
add Some[-1]
add 2 rescue $!
