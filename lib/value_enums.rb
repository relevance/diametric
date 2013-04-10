module Kernel
  def enum(syms)
    prefix = self.name.downcase.sub(/::/, ".")
    syms.each do |s|
      const_set(s.to_s.upcase, ":#{prefix}/#{s.to_s.downcase.sub(/_/, "-")}")
    end
  end
end
