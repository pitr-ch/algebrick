extend Algebrick::DSL                              # => main
extend Algebrick::Matching                         # => main

# Algebraic types very useful for defining data_structures
type_def { tree === tip | node(value: Object, left: tree, right: tree) }
# => [Tree(Tip | Node), Tip, Node(value: Object, left: Tree, right: Tree)]

module Tree
  def depth
    match self,
          Tip.to_m >> 0,
          Node.(_, ~any, ~any) --> left, right { 1 + [left.depth, right.depth].max }

  end
end                                                # => nil

tree = Node[2,
            Tip,
            Node[5,
                 Node[4, Tip, Tip],
                 Node[6, Tip, Tip]]]
# => Node[value: 2, left: Tip, right: Node[value: 5, left: Node[value: 4, left: Tip, right: Tip], right: Node[value: 6, left: Tip, right: Tip]]]
tree.depth                                         # => 3

# and a more real example
type_def {
  package === deb | rpm

  deb(name: String, version: String, revision: Integer, arch: arch)
  rpm(name: String, version: String, release: Integer, arch: arch)

  arch === i386 | amd64 | armel # and more
}
# => [Package(Deb | Rpm), Deb(name: String, version: String, revision: Integer, arch: Arch), Rpm(name: String, version: String, release: Integer, arch: Arch), Arch(I386 | Amd64 | Armel), I386, Amd64, Armel]

module Package
  def full_name
    case self
    when Deb
      name, version, revision, arch = *self
      "#{name}_#{version}-#{revision}_#{arch.full_name}.deb"
    when Rpm
      name, version, release, arch = *self
      "#{name}-#{version}-#{release}-#{arch.full_name}.rpm"
    end
  end
end                                                # => nil

module Arch
  def full_name
    case self
    when I386
      'i386'
    when Amd64
      'amd64'
    when Armel
      'armel'
    end
  end
end                                                # => nil

d = Deb['apt', '1.2.3', 4, I386]
# => Deb[name: apt, version: 1.2.3, revision: 4, arch: I386]
r = Rpm['yum', '1.2.3', 4, Amd64]
# => Rpm[name: yum, version: 1.2.3, release: 4, arch: Amd64]
d.full_name                                        # => "apt_1.2.3-4_i386.deb"
r.full_name                                        # => "yum-1.2.3-4-amd64.rpm"
