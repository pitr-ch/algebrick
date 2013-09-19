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
  I386  = type
  Amd64 = type
  Armel = type
  # ... other architectures omitted

  variants I386, Amd64, Armel
end

Package = Algebrick.type do
  Deb = type do
    fields id:       String,
           version:  String,
           revision: Integer,
           arch:     Arch
    all_readers
  end
  Rpm = type do
    fields id:      String,
           version: String,
           release: Integer,
           arch:    Arch
    all_readers
  end

  variants Deb, Rpm
end

module Package
  def pkg_name
    match self,
          Deb >-> { "#{id}_#{version}-#{revision}_#{arch.pkg_name}.deb" },
          Rpm >-> { "#{id}-#{version}-#{release}-#{arch.pkg_name}.rpm" }
  end
end

module Arch
  def pkg_name
    match self,
          I386  => 'i386',
          Amd64 => 'amd64',
          Armel => 'armel'
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
