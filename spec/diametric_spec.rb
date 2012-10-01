require 'spec_helper'

class Person
  include Diametric

  attr :name, :index => true
end

describe Diametric do
  describe "in a class" do
    subject { Person }

    it { should respond_to(:attr) }
    it { should respond_to(:schema) }
    it { should respond_to(:query) }
    it { should respond_to(:from_query) }
  end

  describe "in an instance" do
    subject { Person.new }

    it { should respond_to(:transact) }
  end
end
