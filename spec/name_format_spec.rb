# frozen_string_literal: true

require "rails_helper"

RSpec.describe "cgsf-name-format" do
  fab!(:user) { Fabricate(:user, name: nil) }

  before { SiteSetting.cgsf_name_format_enabled = true }

  def set_name(name)
    user.name = name
    user.valid?
  end

  it "accepts first name + initial with period" do
    expect(set_name("Maria G.")).to eq(true)
  end

  it "accepts first name + initial without period" do
    expect(set_name("Adam F")).to eq(true)
  end

  it "accepts two given names + initial" do
    expect(set_name("Mary Jo K.")).to eq(true)
  end

  it "accepts apostrophes and hyphens in names" do
    expect(set_name("D'Angelo R.")).to eq(true)
    expect(set_name("Anne-Marie B.")).to eq(true)
  end

  it "shortens a full last name to its initial" do
    expect(set_name("Adam Follmer")).to eq(true)
    expect(user.name).to eq("Adam F.")
  end

  it "shortens after two given names" do
    expect(set_name("Mary Jo Kowalski")).to eq(true)
    expect(user.name).to eq("Mary Jo K.")
  end

  it "fixes lowercase and all-caps typing" do
    expect(set_name("adam f")).to eq(true)
    expect(user.name).to eq("Adam F.")
    expect(set_name("MARIA GARCIA")).to eq(true)
    expect(user.name).to eq("Maria G.")
  end

  it "capitalizes each part of a hyphenated first name" do
    expect(set_name("anne-marie smith")).to eq(true)
    expect(user.name).to eq("Anne-Marie S.")
  end

  it "keeps deliberate capitals and tidies extra spaces" do
    expect(set_name("  DeShawn   Jones ")).to eq(true)
    expect(user.name).to eq("DeShawn J.")
  end

  it "rejects a lone first name" do
    expect(set_name("Adam")).to eq(false)
    expect(user.errors[:name].first).to include("first name and last initial")
  end

  it "rejects more than two given names" do
    expect(set_name("Maria van der Berg")).to eq(false)
  end

  it "leaves blank names to the full-name-required setting" do
    expect(set_name("")).to eq(true)
  end

  it "does not re-validate unchanged names" do
    user.update_columns(name: "Grandfathered Fullname")
    user.reload
    user.username = "newusername"
    expect(user.valid?).to eq(true)
    expect(user.name).to eq("Grandfathered Fullname")
  end

  it "does nothing when disabled" do
    SiteSetting.cgsf_name_format_enabled = false
    expect(set_name("Adam Follmer")).to eq(true)
    expect(user.name).to eq("Adam Follmer")
  end
end
