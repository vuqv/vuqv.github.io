# frozen_string_literal: true

# Backport of the al_folio_core 1.0.16 cache-bust fix (not yet on rubygems).
#
# In 1.0.15 the `?v=` digest on main.css is computed from the theme gem's Sass
# partials only, so editing this site's own _sass/ files (e.g. _custom.scss)
# leaves the URL unchanged and browsers keep serving the stale stylesheet.
# This appends the site's _sass/ contents to the digest input.
#
# Registered in an :after_init hook so it is prepended after al_folio_core's
# own patch and wraps it. Delete this file once al_folio_core >= 1.0.16 is pinned.
module SiteSassCacheBust
  private

  def directory_files_content
    site = Jekyll.sites.last if Jekyll.respond_to?(:sites)
    source = site ? site.source : Dir.pwd
    sass_dir = (site && site.config.dig("sass", "sass_dir")) || "_sass"

    local = Dir[File.join(source, sass_dir, "**", "*")].sort
              .reject { |path| File.directory?(path) }
              .map { |path| File.read(path) }
              .join

    super + local
  end
end

Jekyll::Hooks.register :site, :after_init do
  next unless defined?(Jekyll::CacheBust::CacheDigester)

  digester = Jekyll::CacheBust::CacheDigester
  digester.prepend(SiteSassCacheBust) unless digester.ancestors.include?(SiteSassCacheBust)
end
