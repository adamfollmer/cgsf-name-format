# frozen_string_literal: true

require "rails_helper"

RSpec.describe "cgsf-name-format invite names and name lock" do
  fab!(:admin)
  fab!(:moderator)
  fab!(:member) { Fabricate(:user, name: "Maria G.") }
  fab!(:invite) { Fabricate(:invite, invited_by: admin, email: "newbie@example.com") }

  before do
    SiteSetting.cgsf_name_format_enabled = true
    SiteSetting.cgsf_name_format_lock_names = true
  end

  describe "name lock" do
    it "stops members from changing their own name" do
      expect(Guardian.new(member).can_edit_name?(member)).to eq(false)
    end

    it "lets staff change anyone's name" do
      expect(Guardian.new(admin).can_edit_name?(member)).to eq(true)
      expect(Guardian.new(moderator).can_edit_name?(member)).to eq(true)
    end

    it "ignores a name sent in a member's own profile update" do
      UserUpdater.new(member, member).update(name: "Someone E.")
      expect(member.reload.name).to eq("Maria G.")
    end

    it "lets members edit again when the lock is off" do
      SiteSetting.cgsf_name_format_lock_names = false
      expect(Guardian.new(member).can_edit_name?(member)).to eq(true)
    end
  end

  describe "PUT /cgsf-name-format/invites/:id" do
    it "stores the shaped name for staff" do
      sign_in(admin)
      put "/cgsf-name-format/invites/#{invite.id}.json", params: { name: "jane doe" }
      expect(response.status).to eq(200)
      expect(response.parsed_body["name"]).to eq("Jane D.")
      expect(CgsfNameFormat.invite_name(invite)).to eq("Jane D.")
    end

    it "clears the name when blank" do
      CgsfNameFormat.set_invite_name(invite, "Jane D.")
      sign_in(admin)
      put "/cgsf-name-format/invites/#{invite.id}.json", params: { name: "" }
      expect(response.status).to eq(200)
      expect(CgsfNameFormat.invite_name(invite)).to be_nil
    end

    it "rejects a name it can't shape" do
      sign_in(admin)
      put "/cgsf-name-format/invites/#{invite.id}.json", params: { name: "Jane" }
      expect(response.status).to eq(422)
      expect(CgsfNameFormat.invite_name(invite)).to be_nil
    end

    it "refuses invite links" do
      link = Fabricate(:invite, invited_by: admin, email: nil, max_redemptions_allowed: 5)
      sign_in(admin)
      put "/cgsf-name-format/invites/#{link.id}.json", params: { name: "Jane Doe" }
      expect(response.status).to eq(400)
    end

    it "is staff only" do
      sign_in(member)
      put "/cgsf-name-format/invites/#{invite.id}.json", params: { name: "Jane Doe" }
      expect(response.status).to eq(403)
    end
  end

  describe "GET /cgsf-name-format/invite-name/:invite_key" do
    before { SiteSetting.login_required = true }

    it "returns the name to the logged-out invitee" do
      CgsfNameFormat.set_invite_name(invite, "Jane D.")
      get "/cgsf-name-format/invite-name/#{invite.invite_key}.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body["name"]).to eq("Jane D.")
    end

    it "returns nothing for an unknown key" do
      get "/cgsf-name-format/invite-name/nope.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body["name"]).to be_nil
    end
  end

  describe "redeeming an invite" do
    it "uses the staff-set name over what the invitee typed" do
      CgsfNameFormat.set_invite_name(invite, "Jane D.")
      user =
        invite.redeem(
          email: invite.email,
          username: "janed",
          name: "Typed N.",
          email_verified: true,
        )
      expect(user.name).to eq("Jane D.")
    end

    it "keeps the typed name when staff set none" do
      user =
        invite.redeem(
          email: invite.email,
          username: "janed",
          name: "Typed N.",
          email_verified: true,
        )
      expect(user.name).to eq("Typed N.")
    end
  end
end
