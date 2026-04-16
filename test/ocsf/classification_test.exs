defmodule OCSF.ClassificationTest do
  use ExUnit.Case, async: true

  alias OCSF.Classification

  describe "data_classes/0" do
    test "returns all classes" do
      classes = Classification.data_classes()
      assert :identifier in classes
      assert :tenant in classes
      assert :taxonomic in classes
      assert :temporal in classes
      assert :contact in classes
      assert :identity in classes
      assert :network in classes
      assert :geolocation in classes
      assert :credential in classes
    end
  end

  describe "pii?/1" do
    test "identifies PII classes" do
      assert Classification.pii?(:contact)
      assert Classification.pii?(:identity)
      assert Classification.pii?(:credential)
      refute Classification.pii?(:identifier)
      refute Classification.pii?(:tenant)
      refute Classification.pii?(:network)
    end
  end

  describe "default_policy/1" do
    test "denies PII and network by default" do
      assert Classification.default_policy(:identifier) == :allow
      assert Classification.default_policy(:tenant) == :allow
      assert Classification.default_policy(:taxonomic) == :allow
      assert Classification.default_policy(:temporal) == :allow
      assert Classification.default_policy(:contact) == :deny
      assert Classification.default_policy(:identity) == :deny
      assert Classification.default_policy(:network) == :deny
      assert Classification.default_policy(:geolocation) == :deny
      assert Classification.default_policy(:credential) == :deny
    end
  end
end
