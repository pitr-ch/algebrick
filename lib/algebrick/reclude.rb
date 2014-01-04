module Algebrick
  # fix module to re-include itself to where it was already included when a module is included into it
  #noinspection RubySuperCallWithoutSuperclassInspection
  module Reclude
    def included(base)
      included_into << base
      super(base)
    end

    def include(*modules)
      super(*modules)
      modules.reverse.each do |module_being_included|
        included_into.each do |mod|
          mod.send :include, module_being_included
        end
      end
    end

    private

    def included_into
      @included_into ||= []
    end
  end
end
