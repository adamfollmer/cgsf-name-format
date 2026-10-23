# frozen_string_literal: true

# name: cgsf-name-format
# about: Enforces the Connect St. Francis "First L." display-name convention
# version: 0.3.0
# authors: Adam F.
# url: https://github.com/adamfollmer/cgsf-name-format
# required_version: 2.7.0

enabled_site_setting :cgsf_name_format_enabled

register_asset "stylesheets/cgsf-name-format.scss"

module ::CgsfNameFormat
  # "Maria G." / "Mary Jo K" — one or two given names, then a single initial
  # with optional period. Capitalized, letters only (apostrophes/hyphens ok).
  NAME_FORMAT = /\A\p{Lu}[\p{L}'\-]+(?: \p{Lu}[\p{L}'\-]+)? \p{Lu}\.?\z/

  # Shapes what people naturally type into the convention before validation:
  # "maria garcia" -> "Maria G.", "Mary Jo Kowalski" -> "Mary Jo K.".
  # A lone first name passes through untouched for the validator to explain.
  # Mirrored client-side in assets/javascripts/discourse/lib/cgsf-name-format.js.
  def self.normalize(raw)
    words = raw.to_s.strip.split(/\s+/)
    return raw if words.length < 2

    initial = words.pop[/\p{L}/]
    return raw unless initial

    given = words.map { |w| w.split("-").map { |part| capitalize(part) }.join("-") }
    "#{given.join(" ")} #{initial.upcase}."
  end

  # Fixes all-lowercase/all-caps typing, keeps deliberate casing like "DeShawn".
  def self.capitalize(word)
    return word if word.empty?
    word == word.downcase || word == word.upcase ? word.capitalize : word[0].upcase + word[1..]
  end

  # Staff can set a member's name when they invite them. It is kept per invite
  # and becomes the member's name when they join. Only email invites carry a
  # name: an invite link can be used by several people.
  PLUGIN_NAME = "cgsf-name-format"

  def self.invite_name(invite)
    return if !SiteSetting.cgsf_name_format_enabled || invite.blank? || invite.email.blank?
    PluginStore.get(PLUGIN_NAME, "invite_name_#{invite.id}").presence
  end

  def self.invite_name_for_key(invite_key)
    return if invite_key.blank?
    invite_name(Invite.find_by(invite_key: invite_key.to_s))
  end

  def self.set_invite_name(invite, name)
    if name.blank?
      PluginStore.remove(PLUGIN_NAME, "invite_name_#{invite.id}")
    else
      PluginStore.set(PLUGIN_NAME, "invite_name_#{invite.id}", name)
    end
  end

  def self.names_locked?
    SiteSetting.cgsf_name_format_enabled && SiteSetting.cgsf_name_format_lock_names
  end

  # Once someone joins, only staff change their name (Admin → Users, or their
  # preferences). Members see it as plain text in their own preferences.
  module GuardianExtension
    def can_edit_name?(user)
      return false if ::CgsfNameFormat.names_locked? && !is_staff?
      super
    end
  end

  # Every invite redemption path (email code, password signup) builds an
  # InviteRedeemer, so the staff-set name wins over anything typed at signup.
  module InviteRedeemerExtension
    def initialize(invite:, name: nil, **kwargs)
      super(invite: invite, name: ::CgsfNameFormat.invite_name(invite) || name, **kwargs)
    end
  end

  # When the invite already has a name, the code-login signup skips the name step.
  module SessionControllerExtension
    private

    def signup_full_name_missing?
      return false if ::CgsfNameFormat.invite_name_for_key(params[:invite_key])
      super
    end
  end

  module RedeemWithEmailCodeExtension
    private

    def required_full_name_provided(existing_user:, params:)
      return true if ::CgsfNameFormat.invite_name_for_key(params.invite_key)
      super
    end
  end
end

after_initialize do
  ::Guardian.prepend(::CgsfNameFormat::GuardianExtension)
  ::InviteRedeemer.prepend(::CgsfNameFormat::InviteRedeemerExtension)
  ::SessionController.prepend(::CgsfNameFormat::SessionControllerExtension)
  ::Invite::RedeemWithEmailCode.prepend(::CgsfNameFormat::RedeemWithEmailCodeExtension)

  class ::CgsfNameFormat::InviteNamesController < ::ApplicationController
    requires_plugin ::CgsfNameFormat::PLUGIN_NAME

    before_action :ensure_staff, only: :update
    # The invite page is seen while logged out, on a login-required site.
    skip_before_action :redirect_to_login_if_required, only: :show

    # Staff: set (or clear, with a blank name) the name on an email invite.
    def update
      invite = Invite.find_by(id: params[:id])
      raise Discourse::NotFound if invite.blank?
      raise Discourse::InvalidParameters.new(:id) if invite.email.blank?

      name = params[:name].to_s.strip
      name = ::CgsfNameFormat.normalize(name) if name.present?
      if name.present? && !name.match?(::CgsfNameFormat::NAME_FORMAT)
        return render_json_error(I18n.t("cgsf_name_format.invite_name_invalid"))
      end

      ::CgsfNameFormat.set_invite_name(invite, name)
      render json: success_json.merge(name: name.presence)
    end

    # The invite page: the name this invite will give, for the signup preview.
    def show
      invite = Invite.find_by(invite_key: params[:invite_key].to_s)
      name = ::CgsfNameFormat.invite_name(invite) if invite&.redeemable?
      render json: { name: name }
    end
  end

  Discourse::Application.routes.append do
    put "/cgsf-name-format/invites/:id" => "cgsf_name_format/invite_names#update"
    get "/cgsf-name-format/invite-name/:invite_key" => "cgsf_name_format/invite_names#show"
  end

  add_model_callback(:user, :before_validation) do
    next unless SiteSetting.cgsf_name_format_enabled
    next if id && id < 0
    next if name.blank? || !will_save_change_to_name?

    self.name = CgsfNameFormat.normalize(name)
  end

  add_model_callback(:user, :validate) do
    next unless SiteSetting.cgsf_name_format_enabled
    next if id && id < 0 # system/bot accounts (system, discobot) have non-human names
    next if name.blank? || !will_save_change_to_name?

    unless name.match?(CgsfNameFormat::NAME_FORMAT)
      errors.add(:name, I18n.t("cgsf_name_format.invalid"))
    end
  end
end
