extend Algebrick::DSL
extend Algebrick::Matching

# Algebraic types very useful for defining data_structures
type_def { tree === tip | node(value: Object, left: tree, right: tree) }

module Tree
  def depth
    match self,
          Tip.to_m >> 0,
          Node.(_, ~any, ~any) --> left, right { 1 + [left.depth, right.depth].max }

  end
end

tree = Node[2,
            Tip,
            Node[5,
                 Node[4, Tip, Tip],
                 Node[6, Tip, Tip]]]
tree.depth

# and a more real example
type_def {
  package === deb | rpm

  deb(name: String, version: String, revision: Integer, arch: arch)
  rpm(name: String, version: String, release: Integer, arch: arch)

  arch === i386 | amd64 | armel # and more
}

module Package
  def full_name
    match self,
          Deb >> -> do
            name, version, revision, arch = *self
            "#{name}_#{version}-#{revision}_#{arch.full_name}.deb"
          end,
          Rpm >> -> do
            name, version, release, arch = *self
            "#{name}-#{version}-#{release}-#{arch.full_name}.rpm"
          end
  end
end

module Arch
  def full_name
    match self,
          I386  => 'i386',
          Amd64 => 'amd64',
          Armel => 'armel'
  end
end

d = Deb['apt', '1.2.3', 4, I386]
r = Rpm['yum', '1.2.3', 4, Amd64]
d.full_name
r.full_name
