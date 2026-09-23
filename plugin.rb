# frozen_string_literal: true

# name: cgsf-name-format
# about: Enforces the Connect St. Francis "First L." display-name convention
# version: 0.2.0
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
end

after_initialize do
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
