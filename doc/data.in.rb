extend Algebrick::Matching

# Simple data structures like trees
Tree = Algebrick.type do |tree|
  variants Tip  = type,
           Node = type { fields value: Object, left: tree, right: tree }
end

module Tree
  def depth
    match self,
          Tip.to_m >> 0,
          Node.(any, ~any, ~any) >-> left, right do
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

# Whenever you find yourself to pass around too many fragile Hash-Array structures
# e.g. for menus.
Menu = Algebrick.type do |menu|
  Item = Algebrick.type do
    variants Delimiter = atom,
             Link      = type { fields! label: String, url: String },
             Group     = type { fields! label: String, submenu: menu }
  end

  fields! item: Item, next: menu
  variants None = atom, menu
end
None
Item

module Link
  def self.new(*fields)
    super(*fields).tap { |menu| valid! menu.url }
  end

  def self.valid!(url)
    # stub
  end
end

module Menu
  def +(item)
    Menu[item, self]
  end
end

submenu = None + Link['Red Hat', '#red-hat']
submenu = None + Link['Red Hat', '#red-hat'] + Link['Ubuntu', '#ubuntu']
menu    = None + Link['Home', '#home'] + Delimiter + Group['Linux', submenu] + Link['About', '#about']


#     Group['Products',
#           Menu[]],
#     Link['About', '#about']
#]]
