# frozen_string_literal: true

# name: cgsf-name-format
# about: Enforces the Connect St. Francis "First L." display-name convention
# version: 0.1.0
# authors: Adam F.
# url: https://github.com/adamfollmer/cgsf-name-format
# required_version: 2.7.0

enabled_site_setting :cgsf_name_format_enabled

after_initialize do
  # "Maria G." / "Mary Jo K" — one or two given names, then a single initial
  # with optional period. Capitalized, letters only (apostrophes/hyphens ok).
  NAME_FORMAT = /\A\p{Lu}[\p{L}'\-]+(?: \p{Lu}[\p{L}'\-]+)? \p{Lu}\.?\z/

  add_model_callback(:user, :validate) do
    next unless SiteSetting.cgsf_name_format_enabled
    next if id && id < 0 # system/bot accounts (system, discobot) have non-human names
    next if name.blank? || !will_save_change_to_name?

    unless name.match?(NAME_FORMAT)
      errors.add(:name, I18n.t("cgsf_name_format.invalid"))
    end
  end
end
